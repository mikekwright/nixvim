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

    # This is for rust-analyzer 2024-08-27
    rustanalyzer-nixpkgs.url = "github:nixos/nixpkgs?ref=5629520edecb69630a3f4d17d3d33fc96c13f6fe";

    # This is for the treesitter (and corresponding packages) 2024-08-04
    nvim-treesitter-nixpkgs.url = "github:nixos/nixpkgs?ref=5629520edecb69630a3f4d17d3d33fc96c13f6fe";

    # This is the nvim-lspconfig (and corresponding packages) 2024-08-02
    nvim-lspconfig-nixpkgs.url = "github:nixos/nixpkgs/5629520edecb69630a3f4d17d3d33fc96c13f6fe";

    # This is the telescope-nixpkgs 2024-08-02
    nvim-telescope-nixpkgs.url = "github:nixos/nixpkgs/5629520edecb69630a3f4d17d3d33fc96c13f6fe";

    # This is version 07-28-2024 for nvim-tree-lua
    nvim-tree-lua.url = "github:nixos/nixpkgs/5629520edecb69630a3f4d17d3d33fc96c13f6fe";

    # This is the version used for left sidebar plugins (gitsigns, statuscol, etc.)
    nvim-gitsigns-nixpkgs.url = "github:nixos/nixpkgs/5629520edecb69630a3f4d17d3d33fc96c13f6fe";

    # This is the markdown render tooling
    markdown-nixpkgs.url = "github:nixos/nixpkgs/280db3decab4cbeb22a4599bd472229ab74d25e1";

    # This is the go-tools for neovim (version 0.22.0)
    gotools-nixpkgs.url = "github:nixos/nixpkgs/5ed627539ac84809c78b2dd6d26a5cebeb5ae269";
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
        extra-pkgs = {
          rustanalyzer-pkgs = inputs.rustanalyzer-nixpkgs.legacyPackages.${system};
          pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
          neovim-pkgs = neovim-nixpkgs.legacyPackages.${system};
          nvim-treesitter-pkgs = inputs.nvim-treesitter-nixpkgs.legacyPackages.${system};
          nvim-lspconfig-pkgs = inputs.nvim-lspconfig-nixpkgs.legacyPackages.${system};
          nvim-telescope-pkgs = inputs.nvim-telescope-nixpkgs.legacyPackages.${system};
          nvim-tree-pkgs = inputs.nvim-tree-lua.legacyPackages.${system};
          nvim-gitsign-pkgs = inputs.nvim-gitsigns-nixpkgs.legacyPackages.${system};
          markdown-pkgs = inputs.markdown-nixpkgs.legacyPackages.${system};
          gotools-pkgs = inputs.gotools-nixpkgs.legacyPackages.${system};
        };

        debug = import ./lib/debug.nix {inherit pkgs extra-pkgs system;};
        lib = import ./lib/importer.nix {inherit debug extra-pkgs pkgs system;};

        neovimModule = {
          inherit pkgs extra-pkgs;
          module = import ./config; # import the module directly
          # You can use `extraSpecialArgs` to pass additional arguments to your module files
          extraSpecialArgs = {
            inherit inputs system pkgs debug extra-pkgs;
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
