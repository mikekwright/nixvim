{ neovim-pkgs, pkgs, system, pkgs-unstable, ... }:

let
  loadImports = m: args: if builtins.hasAttr "imports" m
    then builtins.map (i: ((import i) args)) m.imports  # This will call the function to load all the imports
    else [];

  mergeModule = m: args: 
    let
      childrenModules = builtins.trace m (loadImports m args);

      # TODO: Would be nice to create a config section that could just update itself into
      #   the lua config (so more declarative), but that is a future piece of work.
      baseModule = {
        vimPackages = m.vimPackages or [];
        vimOptPackages = m.vimOptPackages or [];
        lua = m.lua or "";
        packages = m.packages or [];
      };

      loadedChildren = builtins.map (m: mergeModule m args) childrenModules;
    in 
      builtins.foldl' (b: m: {
        vimPackages = b.vimPackages ++ m.vimPackages;
        vimOptPackages = b.vimOptPackages ++ m.vimOptPackages;
        lua = b.lua + m.lua;
        packages = b.packages ++ m.packages;
      }) baseModule loadedChildren;
      #builtins.trace loadedChildren baseModule;

in {
  makeModule = m: 
    let
      # The base module from flake is not a common module definition, this kicks off the
      #   process of building and loading all the modules in the system.
      fullModule = mergeModule (m.module m.extraSpecialArgs) m.extraSpecialArgs;

      # Module packages are any other 3rd party packages that are needed when running neovim
      #    such as rust, python, etc (mostly just lsp servers)
      modulePackages = if builtins.hasAttr "packages" fullModule
        then fullModule.packages
        else [];

      # This concats the lua configuration to a single file that is called as the config
      #   for neovim on boot.
      luaText = if builtins.hasAttr "lua" fullModule
        then fullModule.lua
        else "";
      luaFile = (pkgs.writeText "init.lua" luaText);

      # The actual neovim package solution.
      neovimPackage = neovim-pkgs.neovim.override {
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
    #in neovimPackage;
    in (pkgs.writeShellApplication {
      name = "nvim";
      runtimeInputs = [ neovimPackage ] ++ modulePackages;
      text = ''
        echo "Hello, ${luaFile}!" 
        ${neovimPackage}/bin/nvim -u ${luaFile} "$@"
      '';
    });
}

