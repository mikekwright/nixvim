{ pkgs, ... }:
{
  # Import all your configuration modules here
  imports = [
    ./bufferline.nix
    ./settings.nix
    ./keymaps.nix

    ./colorschemes
  ];

  globals.mapleader = ",";

  keymaps = [
    {
      key = "<leader>gg";
      action = "<cmd>Man<CR>";
      options = {
        silent = true;
        remap = false;
      };
    }
  ];

  #colorschemes.gruvbox.enable = true;

  extraPackages = with pkgs; [
  ];

  extraConfigLua = ''
    local g = vim.g
    local o = vim.o

    local opts = { noremap = true, silent = true }
    local term_opts = { silent = true }

    local keymap = vim.keymap.set

    local function nmap(key, op)
      keymap("n", key, op, { silent = true, noremap = true })
    end

    --g.mapleader = ","
    --g.maplocalleader = " "

    local treeApi = require("nvim-tree.api")

    --keymap("", "<Space>", "<Nop>", opts)
    --keymap("", ",", "<Nop>", opts)

    --nmap("<leader>e", treeApi.tree.toggle)
    --nmap(",e", treeApi.tree.toggle)
    --vim.keymap.set("n", "<leader>e", treeApi.tree.toggle, {})

    vim.keymap.set("n", ",e", treeApi.tree.toggle, {})
    --vim.keymap.set("n", " e", treeApi.tree.toggle, {})
    --local map = vim.api.nvim_set_keymap
    --vim.keymap.set('n', '<leader>ff', 'NvimTreeToggle <CR>', {})

    --keymap("n", "<leader>r", function()
    --  vim.wo.relativenumber = not vim.wo.relativenumber
    --end, {})
  '';

  plugins = {
    lualine.enable = true;

    telescope.enable = true;
    oil.enable = true;
    treesitter.enable = true;
    luasnip.enable = true;

    lsp = {
      enable = true;

      servers = {
        tsserver.enable = true;

        lua-ls.enable = true;

        rust-analyzer = {
          enable = true;
          installCargo = true;
          installRustc = true;
        };
      };
    };

    # Options: https://github.com/nix-community/nixvim/blob/main/plugins/filetrees/nvim-tree.nix
    nvim-tree = {
      enable = true;
      openOnSetup = true;
      autoClose = true;

      #onAttach = {
        #__raw = ''
          #function()
            #local api = require("nvim-tree.api")

            #vim.keymap.set("n", "<leader>e", api.tree.toggle, {})
            #vim.keymap.set("n", "<C-P>", api.tree.toggle, {})
          #end
        #'';
      #};

    };

    cmp.settings = {
      enable = false;
      autoEnableSources = true;
      sources = [
        {name = "nvim_lsp";}
        {name = "path";}
        {name = "buffer";}
      ];

      mapping = {
        "<CR>" = "cmp.mapping.confirm({ select = true })";
        "<Tab>" = {
          action = ''
            function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expandable() then
                luasnip.expand()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              elseif check_backspace() then
                fallback()
              else
                fallback()
              end
            end
          '';
          modes = [ "i" "s" ];
        };
      };
    };
  };
}
