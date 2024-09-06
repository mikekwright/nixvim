{ pkgs, inputs, ... }:

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

  packages = with pkgs; [
  ];
}
