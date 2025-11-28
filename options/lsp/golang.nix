{ pkgs, ... }:

let
  name = "lsp.golang";

  lua = /*lua*/ ''
    -- Configure gopls LSP using vim.lsp.config (Neovim 0.11+)
    vim.lsp.config('gopls', {
      cmd = { '${pkgs.gopls}/bin/gopls' },
      filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
    })

    -- Enable gopls LSP
    vim.lsp.enable('gopls')

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
  inherit lua name;

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
