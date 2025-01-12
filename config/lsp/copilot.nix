{pkgs, ...}: let
  copilot-lua =
    /*
    lua
    */
    ''
      require('copilot').setup({
        panel = {
          enabled = false,  -- disable copilot by default, use <cmd>lua require('copilot').toggle()<CR> to toggle
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

      keymapd('<leader>lec', "LSP: Toggle Copilot", function()
        vim.g.copilot_enabled = not vim.g.copilot_enabled
        print("Copilot is now " .. (vim.g.copilot_enabled and "enabled" or "disabled"))
      end)
    '';
in {
  lua = copilot-lua;

  vimPackages = let
    copilot-nvim = pkgs.vimUtils.buildVimPlugin {
      name = "copilot.lua";
      src = pkgs.fetchFromGitHub {
        owner = "zbirenbaum";
        repo = "copilot.lua";
        rev = "86537b286f18783f8b67bccd78a4ef4345679625";
        sha256 = "HC1QZlqEg+RBz/8kjLadafc06UoMAjhh0UO/BWQGMY8=";
      };
    };
  in [
    copilot-nvim
  ];

  packages = with pkgs; [
    nodejs_22 # This is required for copilot
  ];
}
