{
  description = "A neovim flake, mostly around lua";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # This is neovim 0.10.1
    #   Can update this version from here: https://www.nixhub.io/packages/neovim
    neovim-nixpkgs.url = "github:nixos/nixpkgs?ref=5629520edecb69630a3f4d17d3d33fc96c13f6fe";

    # Provide the support for different system configurations and builds
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = {
    neovim-nixpkgs,
    nixpkgs-unstable,
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
        pkgs,
        system,
        ...
      }: let
        pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
        neovim-pkgs = neovim-nixpkgs.legacyPackages.${system};
        debug = (import ./lib/debug.nix { inherit pkgs pkgs-unstable system; });
        lib = (import ./lib/importer.nix { inherit debug neovim-pkgs pkgs system pkgs-unstable; });

        neovimModule = {
          inherit pkgs pkgs-unstable;
          module = import ./config; # import the module directly
          # You can use `extraSpecialArgs` to pass additional arguments to your module files
          extraSpecialArgs = {
            inherit inputs system pkgs ;
          };
        };
        nvim = lib.makeModule neovimModule;
      in {
        checks = {
          # Run `nix flake check .` to verify that your config is not broken
          # TODO: Add the test derivation that can run
          #default = mkTestFrom Module neovimModule;
        };

        packages = {
          # Lets you run `nix run .` to start custom neovim
          default = nvim;
        };
      };
    };
}
