{ pkgs, ... }:

let
  luaConfig = /*lua*/ ''
    require('copilot').setup({
      panel = {
        enabled = true,
        auto_refresh = true,
        keymap = {
          jump_prev = "[[",
          jump_next = "]]",
          accept = "<CR>",
          refresh = "gr",
          open = "<C-P>"
        },
        layout = {
          position = "bottom", -- | top | left | right
          ratio = 0.1
        },
      },

      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = true,
        debounce = 75,
        keymap = {
          accept = "<C-Space>",
          accept_word = false,
          accept_line = false,
          next = "<C-]>",
          prev = "<C-[>",
          dismiss = "<Esc>",
        },
      },

      filetypes = {
        yaml = false,
        markdown = false,
        svn = false,
        cvs = false,
        hgcommit = false
      }
    })
  '';
in
{
  # This appears to be based on the LUA version of the plugin, for more context please review the
  #   associated github repo: https://github.com/zbirenbaum/copilot.lua/

  
  # Be sure to first enable with :Copilot auth (if you aren't already authorized)
  plugins.copilot-chat.enable = true;

  extraConfigLua = luaConfig;

  # extraPackages = with pkgs; [
  #   # Copilot plugin for neovim
  #   #https://search.nixos.org/packages?show=vimPlugins.copilot-lua&from=0&size=50&sort=relevance&type=packages&query=copilot
  #   # The plugin seems to be based on this lua package so we can ignore
  #   vimPlugins.copilot-lua
  # ];
}

