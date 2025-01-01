{ pkgs, debug, ... }:

let
  golangLua =  /*lua*/ ''
    -- lspconfig.rust_analyzer.setup {
    --   capabilities = lsp_cmp_capabilities,
    --
    --   -- Server-specific settings. See `:help lspconfig-setup`
    --   settings = {
    --     ['rust-analyzer'] = {},
    --   },
    -- }
  '';
in
{
  lua = golangLua;

  vimPackages = with pkgs.vimPlugins; [
    nvim-dap-go
  ];

  packages = with pkgs; [
    # This is the lsp server, but requires access to cargo and rustc
    # rust-analyzer

    #rustc
    #rustup
    #cargo
  ];
}
