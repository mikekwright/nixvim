{
  description = "A neovim flake, mostly around lua";

  inputs = {
    # Neovim version 0.11.5
    nixpkgs.url = "github:nixos/nixpkgs/ffcdcf99d65c61956d882df249a9be53e5902ea5";

    # Flake parts for 2025-11-12
    flake-parts.url = "github:hercules-ci/flake-parts/52a2caecc898d0b46b2b905f058ccc5081f842da";

    # Opencode
    # opencode.url = "github:nixos/nixpkgs/306ea70f9eb0fb4e040f8540e2deab32ed7e2055";
    opencode.url = "github:nixos/nixpkgs/bde09022887110deb780067364a0818e89258968";
  };

  outputs = {
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem = {
        config,
        system,
        ...
      }: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        extra-pkgs = {
          opencode = import inputs.opencode {inherit system;};
        };

        debug = import ./lib/debug.nix {inherit pkgs extra-pkgs system;};
        lib = import ./lib/importer.nix {inherit debug extra-pkgs pkgs system;};

        neovimModule = {
          inherit pkgs extra-pkgs;
          module = { ... }: {
            imports = [
              ./common
              ./options
            ];
          };

          # You can use `extraSpecialArgs` to pass additional arguments to your module files
          extraSpecialArgs = {
            inherit inputs system pkgs debug extra-pkgs lib;
          };
        };
      in {
        checks = {
          # Run `nix flake check .` to verify that your config is not broken
          # TODO: Add the test derivation that can run
          #default = mkTestFrom Module neovimModule;
        };

        packages = let
          buildPackage = includes: lib.makeModule includes neovimModule;

          complete-includes = import ./packages/complete.nix {inherit lib;};
          minimal-includes = import ./packages/minimal.nix {inherit lib;};
          python-includes = import ./packages/python.nix {inherit lib;};
          ai-incudes = import ./packages/ai.nix {inherit lib;};
        in rec {
          complete = buildPackage complete-includes;
          minimal = buildPackage minimal-includes;
          python = buildPackage python-includes;
          ai = buildPackage ai-incudes;

          # Lets you run `nix run .` to start custom neovim
          default = complete;
        };
      };
    };
}
