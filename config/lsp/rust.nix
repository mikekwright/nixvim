{ extra-pkgs, debug, ... }:

let
  rustAnalyzerLua = /*lua*/ ''
    lspconfig.rust_analyzer.setup {
      filetypes = { "rust" },
      capabilities = lsp_cmp_capabilities,
      extraOptions = {
        cmd = { "${extra-pkgs.rustanalyzer-pkgs.rust-analyzer}/bin/rust-analyzer" },

        cargo = {
          allFeatures = true,
        },
      },

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

    #rustc
    #rustup
    #cargo
  ];
}
