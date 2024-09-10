{ pkgs, ... }:

let
  nix-lsp-lua = /*lua*/ ''
    lspconfig.nixd.setup {
      capabilities = lsp_cmp_capabilities,
      --capabilities = vim.lsp.protocol.make_client_capabilities()

      -- Server-specific settings. See `:help lspconfig-setup`
      settings = {
        ['rust-analyzer'] = {},
      },
    }
  '';
in
{
  lua = nix-lsp-lua;

  vimPackages = with pkgs.vimPlugins; [
    vim-nix
  ];

  packages = with pkgs; [
    nixd
  ];
}
