{ pkgs, ... }:

let
  name = "lsp.coc.golang";

  lua = /* lua */ ''
    _G.ensure_coc_extension('coc-go')

    if neotest_adapters ~= nil then
      local golang_neotest_config = {
        go_test_args = {
          '-v',
          '-race',
          '-count=1',
          '-coverprofile=' .. vim.fn.getcwd() .. '/coverage.out',
        },
      }
      table.insert(neotest_adapters, require('neotest-golang')(golang_neotest_config))
    end
  '';
in
{
  inherit lua name;

  vimPackages = with pkgs.vimPlugins; [
    vim-go
    neotest-golang
  ];

  startScript = /* bash */ ''
    unset GOROOT
  '';

  packages = with pkgs; [
    gotools
    gopls
  ];
}
