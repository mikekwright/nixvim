{pkgs, ...}: let
  conformLua =
    /*
    lua
    */
    ''
      local conform = require('conform')
      conform.setup({
        -- For more options check out the github
        --   https://github.com/stevearc/conform.nvim?tab=readme-ov-file#customizing-formatters
        formatters = {
          alejandra = {
            command = "${pkgs.alejandra}/bin/alejandra",
          },
          prettier = {
            command = "${pkgs.nodePackages.prettier}/bin/prettier",
          }
        },

        formatters_by_ft = {
          nix = { "alejandra" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          javascriptreact = { "prettier" },
          typescriptreact = { "prettier" },
          svelte = { "prettier" },
          css = { "prettier" },
          html = { "prettier" },
          json = { "prettier" },
          yaml = { "prettier" },
          markdown = { "prettier" },
          graphql = { "prettier" },
          liquid = { "prettier" },
        },
      })

      keymapd("<leader>lf", "Format the file or selection", function()
        conform.format({
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
        })
      end)
    '';
in {
  lua = conformLua;

  packages = with pkgs; [
    alejandra # Uncompromissing nix formatter
    nodePackages.prettier # For js,tsx,css,etc.
  ];

  vimPackages = let
    conform-nvim = pkgs.vimUtils.buildVimPlugin {
      name = "conform.nvim";
      src = pkgs.fetchFromGitHub {
        owner = "stevearc";
        repo = "conform.nvim";
        rev = "v8.1.0";
        sha256 = "dM7nJi9pAP8OuUswviHzEPXrlR5/fZC/8bhiVnnvhPg=";
      };
    };
  in [
    conform-nvim
  ];
}
