{ pkgs, ... }:

let
  name = "lsp.python";

  lua = /*lua*/ ''
    vim.lsp.config('pyright', {
      settings = {
        pyright = {},
      },
    })
    vim.lsp.enable('pyright')

    table.insert(neotest_adapters, require("neotest-python")({
      dap = { justMyCode = false },
    }))
  '';
in
{
  inherit lua name;

  vimPackages = with pkgs.vimPlugins; [
    nvim-dap-python
    neotest-python
  ];

  packages = with pkgs; [
    pyright
  ];
}
