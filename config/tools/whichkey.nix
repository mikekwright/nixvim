{ pkgs, ... }:

let
  whichkey_lua = /*lua*/ ''

  local wk = require("which-key")
    wk.add({
      --
      -- Start with the overview of the list of specific groups include
      --   
      --   g -- Goto places (last, bookmarks, etc)
      --   e -- Explore (tree, etc)
      --   f -- find (files, etc)
      --   h -- Help 
      --   l -- Language (LSP support)  
      --   d -- Debug
      --   r -- Run
      --   t -- Terminal
      --   b -- Buffers
      --


      --   a -- (Nothing)
      --   b -- Bookmarks
      --   ,d -- Debug
      --   ,

      { "<leader>e", group = "Tree", desc = "Nvim tree" },
      { "<leader>ef", group = "Files" }, -- group
      { "<leader>

      { "<leader>w", proxy = "<c-w>", group = "windows" }, -- proxy to window mappings
      { "<leader>g", group = "buffers", expand = function()
          return require("which-key.extras").expand.buf()
        end
      },
      { "<leader>c", group = "Console",  desc = "Work with view on page" },
      { "<leader>t", group = "Terminal", desc = "Terminal support" },
      { "<leader>b", group = "Bookmarks", desc = "Bookmarks" },

      { "<leader>r", group = "Run", desc = "Run" },
      -- {
      --   -- Nested mappings are allowed and can be added in any order
      --   -- Most attributes can be inherited or overridden on any level
      --   -- There's no limit to the depth of nesting
      --   -- mode = { "n", "v" }, -- NORMAL and VISUAL mode
      --   { "<leader>q", "<cmd>q<cr>", desc = "Quit" }, -- no need to specify mode since it's inherited
      --   { "<leader>w", "<cmd>w<cr>", desc = "Write" },
      -- }
      { "<leader>le", group = "LSP: Tool Enabling", desc = "Toggle LSP Tooling" },
    })

  keymap("<leader>?", function()
    require("which-key").show({ global = true })
  end)
  '';
in
{
  lua = whichkey_lua;

  vimPackages =
    let
      # Pretty cool helper tool for neovim
      #   https://github.com/folke/which-key.nvim
      whichkey-nvim = pkgs.vimUtils.buildVimPlugin {
        name = "whichkey";
        src = pkgs.fetchFromGitHub {
          owner = "folke";
          repo = "which-key.nvim";
          rev = "v3.13.3";
          sha256 = "P3Uugc+RPsRVD/kFCmHDow3PLeb2oXEbNX3WzoZ9xlw=";
        };
      };
    in [
      whichkey-nvim
    ];
}
