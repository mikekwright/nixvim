{ pkgs, ... }:

let
  name = "lsp.python";

  lua = /*lua*/ ''
    lspconfig.pyright.setup {
      capabilities = lsp_cmp_capabilities,

      -- Server-specific settings. See `:help lspconfig-setup`
      settings = {
        pyright = {},
      },
    }

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
