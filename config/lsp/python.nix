{ pkgs, ... }:

let
  python-lsp-lua = /*lua*/ ''
    lspconfig.pyright.setup {
      capabilities = lsp_cmp_capabilities,

      -- Server-specific settings. See `:help lspconfig-setup`
      settings = {
        pyright = {},
      },
    }
  '';
in
{
  lua = python-lsp-lua;

  vimPackages = [
  ];

  packages = with pkgs; [
    pyright
  ];
}
