{ neovim-pkgs, pkgs, system, pkgs-unstable, ... }:

let
  loadImports = m: args: if builtins.hasAttr "imports" m
    then (i: (i args)) m.imports  # This will call the function to load all the imports
    else [];

  mergeModule = m: args: 
    let
      childrenModules = (loadImports m args);

      baseModule = {
        vimPackages = m.vimPackages or [];
        lua = m.lua or "";
        packages = m.packages or [];
      };
    in baseModule;

in {
  makeModule = m: 
    let
      fullModule = mergeModule (m.module m.extraSpecialArgs) m.extraSpecialArgs;

      # This is where the key logic for setting up the package
      #   should go.
      luaText = if builtins.hasAttr "lua" fullModule
        then fullModule.lua
        else "";

      modulePackages = if builtins.hasAttr "packages" fullModule
        then fullModule.packages
        else [];

      luaFile = (pkgs.writeText "init.lua" luaText);

      neovimPackage = neovim-pkgs.neovim.override {
        configure = {
          #  This is trying to load as a vimscript file, not lua.  Need to
          #     continue to investigate.
          #customRC = luaText;

          #  Install all the needed plugins at this point.
          packages.myVimPackage = {
            start = fullModule.vimPackages;
            opt = [ ];
          };
        };
      };
    in neovimPackage;
    # in (pkgs.writeShellApplication {
    #   name = "nvim";
    #   runtimeInputs = [ neovimPackage ] ++ modulePackages;
    #   text = ''
    #     echo "Hello, ${luaFile}!" 
    #     ${neovimPackage}/bin/nvim -u ${luaFile} "$@"
    #   '';
    # });
}

