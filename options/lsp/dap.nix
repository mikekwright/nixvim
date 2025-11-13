{ pkgs, ... }:

let
  name = "lsp.dap";

  lua = /*lua*/ ''
    local dap_plugin = require('dap')

    vim.keymap.set("n", '<leader>rd', function()
      dap_plugin.continue()
    end, { desc = "Start/Continue Debug" })
  '';
in
{
  inherit lua name;

  vimPackages = with pkgs.vimPlugins; [
    # This is the plugin that uses microsoft's debug adapter protocol (DAP)
    nvim-dap
    nvim-dap-ui
  ];
}
