{ pkgs, ... }:

# This file contains the plugin support for winshift that allows for window movement
#   https://github.com/sindrets/winshift.nvim
let
  luaConfig = (builtins.readFile ./lua/winshift.lua);
in
{
  extraPackages = with pkgs.vimPlugins; [
    winshift-nvim
  ];

  extraConfigLua = luaConfig;
}

