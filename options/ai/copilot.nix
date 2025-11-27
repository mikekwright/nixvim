{pkgs, ...}: let
  name = "ai.copilot";

  lua =
    /*
    lua
    */
    ''
      require('copilot').setup({
        panel = {
          enabled = false,  -- disable copilot panel by default
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
          enabled = false,  -- Disabled because we use blink-copilot for completions
        },

        filetypes = {
          yaml = false,
          markdown = false,
          svn = false,
          cvs = false,
          hgcommit = false
        }
      })

      -- Keymap to toggle copilot
      keymapd('<leader>lec', "AI: Toggle Copilot", function()
        vim.g.copilot_enabled = not vim.g.copilot_enabled
        print("Copilot is now " .. (vim.g.copilot_enabled and "enabled" or "disabled"))
      end)
    '';
in {
  inherit lua name;

  vimPackages = with pkgs.vimPlugins; [
    copilot-lua
    blink-copilot
  ];

  packages = with pkgs; [
    nodejs_22 # Required for copilot
  ];
}
