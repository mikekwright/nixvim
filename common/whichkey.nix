{ pkgs, ... }:

let
  whichkey_lua = /*lua*/ ''

  local wk = require("which-key")
    wk.add({
      --
      -- Start with the overview of the list of specific groups include
      --   
      --   ? -- General help (Defined below)
      --   m -- Goto places (last, bookmarks, etc)
      { "<leader>m", group = "Move/Bookmark", desc = "Goto/Bookmark" },
      --   g -- Git commands
      { "<leader>g", group = "Git", desc = "Git" },
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

      --   a -- AI
      { "<leader>a", group = "AI", desc = "AI Tools" },

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

  vimPackages =with pkgs.vimPlugins; [
    which-key-nvim
  ];
}
