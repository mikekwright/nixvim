{ pkgs, ... }:

let
  goLua = /*lua*/ ''
    lspconfig.gopls.setup({
      filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
      capabilities = lsp_cmp_capabilities,
      extraOptions = {
        cmd = { '${pkgs.gopls}/bin/gopls' },
      },
    })

    local golang_neotest_config = { -- Specify configuration
      go_test_args = {
        "-v",
        "-race",
        "-count=1",
        "-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out",
      },
    }
    table.insert(neotest_adapters, require("neotest-golang")(golang_neotest_config))
  '';
in
{
  lua = goLua;

  vimPackages = with pkgs.vimPlugins; [
    vim-go
    neotest-golang
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
