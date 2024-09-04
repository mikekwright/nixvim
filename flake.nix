{
  description = "A neovim flake, mostly around lua";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # This is neovim 0.10.1
    neovim.url = "github:nixos/nixpkgs?ref=5629520edecb69630a3f4d17d3d33fc96c13f6fe";

    # Provide the support for different system configurations and builds
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = {
    neovim,
    nixpkgs,
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
        neovim-pkgs = neovim.legacyPackages.${system};

        nixvimLib = (import ./lib { inherit neovim-pkgs pkgs system pkgs-unstable; });

        nixvimModule = {
          inherit pkgs pkgs-unstable;
          module = import ./config; # import the module directly
          # You can use `extraSpecialArgs` to pass additional arguments to your module files
          extraSpecialArgs = {
            inherit inputs system pkgs ;
          };
        };
        nvim = nixvimLib.makeModule nixvimModule;
      in {
        checks = {
          # Run `nix flake check .` to verify that your config is not broken
          #default = nixvimLib.check.mkTestDerivationFromNixvimModule nixvimModule;
        };

        packages = {
          # Lets you run `nix run .` to start nixvim
          default = nvim;
        };
      };
    };

  #outputs = { self, nixpkgs }: {
  #  packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
  #
  #  packages.x86_64-linux.default = self.packages.x86_64-linux.hello;
  #};
}
