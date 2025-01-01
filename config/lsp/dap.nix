{ pkgs, ... }:
{
  vimPackages = with pkgs.vimPlugins; [
    # This is the plugin that uses microsoft's debug adapter protocol (DAP)
    nvim-dap
    nvim-dap-ui
  ];
}
