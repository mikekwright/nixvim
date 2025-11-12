{ pkgs, ... }:

let
  name = "lsp.nix";

  lua = /*lua*/ ''
    lspconfig.nixd.setup {
      capabilities = lsp_cmp_capabilities,
      extraOptions = {
        cmd = { "${pkgs.nixd}/bin/nixd" };
      };

      --capabilities = vim.lsp.protocol.make_client_capabilities()
      -- Server-specific settings. See `:help lspconfig-setup`
      settings = {
        ['rust-analyzer'] = {},
      },
    }
  '';
in
{
  inherit lua name;

  vimPackages = with pkgs.vimPlugins; [
    vim-nix
  ];

  packages = with pkgs; [
    nixd

    statix
  ];
}
