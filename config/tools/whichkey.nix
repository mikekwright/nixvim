{ pkgs, ... }:

let
  whichkey_lua = /*lua*/ ''

  local wk = require("which-key")
    wk.add({
      { "<leader>f", group = "File work" }, -- group
      -- { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File", mode = "n" },
      -- { "<leader>fb", function() print("hello") end, desc = "Foobar" },
      { "<leader>fn", desc = "New File" },
      -- { "<leader>f1", hidden = true }, -- hide this keymap
      { "<leader>w", proxy = "<c-w>", group = "windows" }, -- proxy to window mappings
      { "<leader>g", group = "buffers", expand = function()
          return require("which-key.extras").expand.buf()
        end
      },
      { "<leader>c", group = "Console",  desc = "Work with view on page" },
      { "<leader>e", group = "Nvim tree", desc = "Nvim tree" },
      { "<leader>t", group = "Terminal", desc = "Terminal support" },
      { "<leader>b", group = "Bookmarks", desc = "Bookmarks" },
      -- {
      --   -- Nested mappings are allowed and can be added in any order
      --   -- Most attributes can be inherited or overridden on any level
      --   -- There's no limit to the depth of nesting
      --   -- mode = { "n", "v" }, -- NORMAL and VISUAL mode
      --   { "<leader>q", "<cmd>q<cr>", desc = "Quit" }, -- no need to specify mode since it's inherited
      --   { "<leader>w", "<cmd>w<cr>", desc = "Write" },
      -- }
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
