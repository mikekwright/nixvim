{
  description = "A neovim flake, mostly around lua";

  inputs = {
    # Neovim version 0.12.4
    nixpkgs.url = "github:nixos/nixpkgs/f6776b4d899bca9dc8f99ee9b2c6c12d778f9233";

    # Flake parts for 2026-08-01
    flake-parts.url = "github:hercules-ci/flake-parts/427bf4bd9435fdf21321c8cc628c24efc14c0f7a";

    # Track: 
    #   master - https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/op/opencode/package.nix
    #   unstable - https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/op/opencode/package.nix
    opencode.url = "github:nixos/nixpkgs/9d590febde3a5eae8a2fbb70a45f5391bde62214";

    # Track:
    #   master - https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/cl/claude-code/package.nix
    #   unstable - https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/cl/claude-code/package.nix 
    claude-code.url = "github:nixos/nixpkgs/0207bfa1f135caa7135303b34dcf64f739f390f7";
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
          opencode = import inputs.opencode {inherit system; };
          claude-code = import inputs.claude-code { inherit system; config.allowUnfree = true; };
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
          full-includes = import ./packages/full.nix {inherit lib;};
          minimal-includes = import ./packages/minimal.nix {inherit lib;};
          python-includes = import ./packages/python.nix {inherit lib;};
          ai-incudes = import ./packages/ai.nix {inherit lib;};
        in rec {
          complete = buildPackage complete-includes;
          full = buildPackage full-includes;
          minimal = buildPackage minimal-includes;
          python = buildPackage python-includes;
          ai = buildPackage ai-incudes;

          # Lets you run `nix run .` to start custom neovim
          default = complete;
        };
      };
    };
}
