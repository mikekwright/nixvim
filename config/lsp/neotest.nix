{ pkgs, ... }:
{
  vimPackages = with pkgs.vimPlugins; [
    # This plugin is supposed to make it easier to setup and use tests in conjunction with
    #   the project structures that you are supporting
    # https://github.com/nvim-neotest/neotest
    neotest
  ];
}
