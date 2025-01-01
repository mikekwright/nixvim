{ extra-pkgs, ... }:

let
  pkgs = extra-pkgs.gotools-pkgs;

  goLua = /*lua*/ ''
    lspconfig.gopls.setup({
      filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
      capabilities = lsp_cmp_capabilities,
      extraOptions = {
        cmd = { '${pkgs.gopls}/bin/gopls' },
      },
    })
  '';
in
{
  lua = goLua;

  vimPackages = with pkgs.vimPlugins; [
    vim-go
  ];

  startScript = /*bash*/ ''
    unset GOROOT
  '';

  packages = with pkgs; [
    gotools

    # This is the language server for Go
    gopls
  ];
}
