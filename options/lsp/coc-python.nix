{ pkgs, ... }:

let
  name = "lsp.coc.python";

  lua = /* lua */ ''
    _G.coc_merge_config({
      languageserver = {
        basedpyright = {
          command = '${pkgs.basedpyright}/bin/basedpyright-langserver',
          args = { '--stdio' },
          filetypes = { 'python' },
          rootPatterns = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
          settings = {
            basedpyright = {},
            python = {
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
      },
    })

    if neotest_adapters ~= nil then
      table.insert(neotest_adapters, require('neotest-python')({
        dap = { justMyCode = false },
      }))
    end
  '';
in
{
  inherit lua name;

  vimPackages = with pkgs.vimPlugins; [
    nvim-dap-python
    neotest-python
  ];

  packages = with pkgs; [
    basedpyright
  ];
}
