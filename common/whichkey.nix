{ pkgs, ... }:

let
  whichkey_lua = /*lua*/ ''

  local wk = require("which-key")
    wk.add({
      --
      -- Start with the overview of the list of specific groups include
      --   
      --   ? -- General help (Defined below)
      --   g -- Goto places (last, bookmarks, etc)
      { "<leader>g", group = "Goto", desc = "Goto" },
      --   e -- Explore (tree, etc)
      { "<leader>e", group = "Explore", desc = "Quickly view / explore" },
      --   f -- find (files, etc)
      { "<leader>f", group = "Find", desc = "Find content" },
      --   h -- Help 
      { "<leader>h", group = "Help", desc = "General Help" },
      --   l -- Language (LSP support)  
      { "<leader>l", group = "LSP", desc = "Commands for working with LSP" },
      --   d -- Debug
      { "<leader>d", group = "Debug", desc = "Debug commands" },
      --   r -- Run
      { "<leader>r", group = "Run", desc = "Run commands" },
      --   t -- Terminal
      { "<leader>t", group = "Terminal", desc = "Terminal commands" },
      --   b -- Buffers
      { "<leader>b", group = "Buffers", desc = "Buffer commands" },
      --   w -- Window
      { "<leader>w", proxy = "<c-w>", group = "Windows", desc = "Window commands" },
      --   q -- Quit
      { "<leader>q", group = "Quit", desc = "Quit commands" },
      --   k -- Comment
      { "<leader>k", group = "Comment", desc = "Comment commands" },

      -- { "<leader>g", group = "buffers", expand = function()
      --     return require("which-key.extras").expand.buf()
      --   end
      -- },
      -- {
      --   -- Nested mappings are allowed and can be added in any order
      --   -- Most attributes can be inherited or overridden on any level
      --   -- There's no limit to the depth of nesting
      --   -- mode = { "n", "v" }, -- NORMAL and VISUAL mode
      --   { "<leader>q", "<cmd>q<cr>", desc = "Quit" }, -- no need to specify mode since it's inherited
      --   { "<leader>w", "<cmd>w<cr>", desc = "Write" },
      -- }
      -- { "<leader>le", group = "LSP: Tool Enabling", desc = "Toggle LSP Tooling" },
    })

  keymapd("<leader>?", "Show all keys from whick-hey", function()
    require("which-key").show({ global = true })
  end)
  '';
in
{
  common = true;

  lua = whichkey_lua;

  vimPackages =
    # let
    #   lazy-nvim = pkgs.vimUtils.buildVimPlugin {
    #     name = "whichkey";
    #     src = pkgs.fetchFromGitHub {
    #       owner = "folke";
    #       repo = "lazy.nvim";
    #       rev = "85c7ff3711b730b4030d03144f6db6375044ae82";
    #       sha256 = "h5404njTAfqMJFQ3MAr2PWSbV81eS4aIs0cxAXkT0EM=";
    #     };
    #
    #   };
    #
    #   # Pretty cool helper tool for neovim
    #   #   https://github.com/folke/which-key.nvim
    #   whichkey-nvim = pkgs.vimUtils.buildVimPlugin {
    #     name = "whichkey";
    #     src = pkgs.fetchFromGitHub {
    #       owner = "folke";
    #       repo = "which-key.nvim";
    #       rev = "3aab2147e74890957785941f0c1ad87d0a44c15a";
    #       sha256 = "1dwri7gxqgb58pfy829s0ns709m0nrcj1cgz2wj1k09qfffri9mc";
    #     };
    #
    #     dependencies = [
    #       lazy-nvim
    #     ];
    #   };
    # in [
    #   whichkey-nvim
    # ];
    with pkgs.vimPlugins; [
      which-key-nvim
    ];
}
