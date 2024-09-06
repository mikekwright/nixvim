{ pkgs, extra-pkgs, ... }:

let
  rustAnalyzerLua = /*lua*/ ''
    lspconfig.rust_analyzer.setup {
      -- Server-specific settings. See `:help lspconfig-setup`
      settings = {
        ['rust-analyzer'] = {},
      },
    }
  '';
in
{
  lua = rustAnalyzerLua;

  packages = with extra-pkgs.rustanalyzer-pkgs; [
    # This is the lsp server, but requires access to cargo and rustc
    rust-analyzer

    rustc
    rustup
    cargo
  ];
}
