{ pkgs, ... }:

let
  name = "lsp.python";

  lua = /*lua*/ ''
    -- Configure pyright LSP using vim.lsp.config (Neovim 0.11+)
    vim.lsp.config('pyright', {
      -- Server-specific settings. See `:help vim.lsp.config`
      settings = {
        pyright = {},
      },
    })

    -- Enable pyright LSP
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
