{ pkgs, ... }:

let
  copilot-lua = /*lua*/ ''
    require('CopilotChat').setup({})

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

    copilot-chat-nvim = pkgs.vimUtils.buildVimPlugin {
      name = "copilot.vim";
      src = pkgs.fetchFromGitHub {
        owner = "CopilotC-Nvim";
        repo = "CopilotChat.nvim";
        rev = "v2.14.0";
        sha256 = "8msw3gw7eQbZitSZxeigL+zACVBiGxoGJUlOimKOXPE=";
      };
    };
  in [
    copilot-nvim
    copilot-chat-nvim
  ];

  packages = with pkgs; [
    nodejs_22  # This is required for copilot
  ];
}
