{ neovim-pkgs, pkgs, system, pkgs-unstable, ... }:

let
  mergeModule = m: {
    vimPackages = m.vimPackages or [];
    lua = m.lua or "";
    packages = m.packages or [];
  };

  jellybeans = pkgs.vimUtils.buildVimPlugin {
    name = "vim-jellybeans";
    src = pkgs.fetchFromGitHub {
      owner = "mikekwright";
      repo = "jellybeans.vim";
      rev = "ef83bf4dc8b3eacffc97bf5c96ab2581b415c9fa";
      sha256 = "X+37Mlyt6+ZwfYlt4ZtdHPXDgcKtiXlUoUPZVb58w/8=";
    };
  };

  nvimHelloWorld = pkgs.vimUtils.buildVimPlugin {
    name = "nvim-hello-world";
    src = pkgs.fetchFromGitHub {
      owner = "jw3126";
      repo = "nvim-hello-world";
      rev = "4128bd645bcac1d2e4bbbfca014f10e0b7f1b1b3";
      sha256 = "36vs8tL4YMiBBWXaFO1ynEl82fg8ja/6kiSN44I3XQs=";
    };
  };
in {
  makeModule = module: 
    let
      fullModule = mergeModule module;

      # This is where the key logic for setting up the package
      #   should go.
      luaText = if builtins.hasAttr "lua" fullModule
        then fullModule.lua
        else "";

      modulePackages = if builtins.hasAttr "packages" fullModule
        then fullModule.packages
        else [];

      #luaFile = (pkgs.writeText "luaFile.lua" luaText);
      luaFile = (pkgs.writeText "init.lua" ''require("hello-world").greet()'');

      neovimPackage = neovim-pkgs.neovim.override {
        configure = {
          #lua = luaFile;
          #customRC = luaText;
          packages.myVimPackage = {
            start = [ jellybeans nvimHelloWorld ];
            opt = [ ];
          };
        };
      };
    #in neovimPackage;
    in (pkgs.writeShellApplication {
      name = "nvim";
      #runtimeInputs = [ pkgs.neovim ] ++ modulePackages;
      runtimeInputs = [ neovimPackage ] ++ modulePackages;
      text = ''
        echo "Hello, ${luaFile}!" 
        ${neovimPackage}/bin/nvim -u ${luaFile} "$@"
      '';
    });
}

