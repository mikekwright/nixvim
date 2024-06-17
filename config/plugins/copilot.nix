{ pkgs, ... }:

let
  luaConfig = (builtins.readFile ./lua/copilot.lua);
in
{
  # Be sure to first enable with :Copilot auth (if you aren't already authorized)
  plugins.copilot-chat.enable = true;

  extraConfigLua = luaConfig;

  extraPackages = with pkgs; [
    # Copilot plugin for neovim
    #https://search.nixos.org/packages?show=vimPlugins.copilot-lua&from=0&size=50&sort=relevance&type=packages&query=copilot
    # The plugin seems to be based on this lua package so we can ignore
    #vimPlugins.copilot-lua
  ];

}

