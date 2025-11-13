{ pkgs, debug, ... }:

let
  loadOption = options: flag: attr:
    {
      inherit (attr) name imports;

      lua = options.extensions flag attr.lua;
      afterLua = options.extensions flag attr.afterLua;
      startScript = options.extensions flag attr.startScript;
      vimPackages = options.extensions flag attr.vimPackages;
      vimOptPackages = options.extensions flag attr.vimOptPackages;

      packages = options.packages flag attr.packages;
    };

  loadImports = m: args: if builtins.hasAttr "imports" m
    then builtins.map (i: ((import i) args) // { }) m.imports
    else [];

  mergeModule = m: options: args:
    let
      childrenModules = debug.trace m (loadImports m args);

      # TODO: Would be nice to create a config section that could just update itself into
      #   the lua config (so more declarative), but that is a future piece of work.
      originalModule = {
        common = m.common or false;
        name = m.name or "default";
        vimPackages = m.vimPackages or [];
        vimOptPackages = m.vimOptPackages or [];
        lua = m.lua or "";
        afterLua = m.afterLua or "";
        packages = m.packages or [];
        startScript = m.startScript or "";
      };

      baseModule = if originalModule.common
        then originalModule
        else loadOption options originalModule.name originalModule;

      # This is the recursive check to basically pull all the other modules that we
      #   have.
      loadedChildren = builtins.map (m: mergeModule m options args) childrenModules;

      completedMerge = builtins.foldl' (b: m: {
        vimPackages = b.vimPackages ++ m.vimPackages;
        vimOptPackages = b.vimOptPackages ++ m.vimOptPackages;
        lua = b.lua + (if m.lua == "" then "" else /*lua*/ ''
          ${"\t"}---- BEGIN ${m.name or "unknown"} ----

          '' + m.lua + /*lua*/ ''
          ${"\t"}---- END ${m.name or "unknown"} ----

          '');
        afterLua = (if m.afterLua == "" then "" else /*lua*/ ''
          ${"\t"}---- BEGIN ${m.name or "unknown"} AFTERLUA ----

          '' +  m.afterLua + /*lua*/ ''
          ${"\t"}---- END ${m.name or "unknown"} AFTERLUA ----

          '') + b.afterLua;
        packages = b.packages ++ m.packages;
        startScript = b.startScript + m.startScript;
      }) baseModule loadedChildren;
    in 
      debug.trace completedMerge completedMerge;
in {
  makeIncludes = includes: {
    extensions = includes.extensions or [];
    packages = includes.packages or [];
    complete = includes.complete or [];
    ai = includes.ai or [];
  };

  makeModule = includes: m: 
    let
      # This options is what will be used to include the specific extensions
      #    an packages that are desired for the given setup
      options = import ./options.nix { inherit includes; };

      # The base module from flake is not a common module definition, this kicks off the
      #   process of building and loading all the modules in the system.
      fullModule = mergeModule (m.module m.extraSpecialArgs) options m.extraSpecialArgs;

      # Module packages are any other 3rd party packages that are needed when running neovim
      #    such as rust, python, etc (mostly just lsp servers)
      modulePackages = if builtins.hasAttr "packages" fullModule
        then fullModule.packages
        else [];

      # This concats the lua configuration to a single file that is called as the config
      #   for neovim on boot.
      luaStartText = if builtins.hasAttr "lua" fullModule
        then fullModule.lua
        else "";

      luaAfterText = if builtins.hasAttr "afterLua" fullModule
        then fullModule.afterLua
        else "";

      luaFile = pkgs.writeText "init.lua" (luaStartText + luaAfterText);

      scriptText = fullModule.startScript;       # The actual neovim package solution.

      neovimPackage =  pkgs.neovim.override {
        configure = {
          #  This is trying to load as a vimscript file, not lua.  Need to
          #     continue to investigate.
          #customRC = luaText;

          #  Install all the needed plugins at this point.
          packages.myVimPackage = {
            start = fullModule.vimPackages;
            opt = fullModule.vimOptPackages;
          };
        };
      };

      neowrapper = pkgs.writeShellApplication {
        name = "nvim";
        runtimeInputs = [ neovimPackage ] ++ modulePackages;
        text = /*shell*/ ''
          set +u
          if [[ -n $NVIM_DEBUG ]]; then
            echo 'LUA CONFIG FILE: ${luaFile}'
            cat ${luaFile}

            echo 'Startup scripts:'
            echo '${scriptText}'

            echo '-------------------------'
            echo "Neovim config file path: ${luaFile}" 
          else
            ${scriptText}
            ${neovimPackage}/bin/nvim -u ${luaFile} "$@"
          fi
        '';
      };
    in pkgs.stdenv.mkDerivation rec {
      name = "nvim";
      buildCommand = let
        desktopEntry = pkgs.makeDesktopItem {
          inherit name;
          desktopName = "Neovim";
          exec = "${neowrapper}/bin/${name} %f";
          terminal = true;
        };
      in ''
        mkdir -p $out/bin
        cp ${neowrapper}/bin/${name} $out/bin
        mkdir -p $out/share/applications
        cp ${desktopEntry}/share/applications/${name}.desktop $out/share/applications/${name}.desktop
      '';
      dontBuild = true;
    };
}

