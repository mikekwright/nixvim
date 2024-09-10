{ ... }:

let
  initialLua = /*lua*/ ''
    -- As we are trying to optimize our solution for just config defined in this flake we need
    --    to have our system ignore default configs (these are shared from online sources)
    vim.opt.runtimepath:remove(vim.fn.stdpath('config'))              -- ~/.config/nvim
    vim.opt.runtimepath:remove(vim.fn.stdpath('config') .. "/after")  -- ~/.config/nvim/after
    vim.opt.runtimepath:remove(vim.fn.stdpath('data') .. "/site")     -- ~/.local/share/nvim/site

    -- disable netrw at the very start of your init.lua
    vim.g.loaded_netrw = 1;
    vim.g.loaded_netrwPlugin = 1;

    -- Set the leader key
    vim.g.mapleader = ',';
    vim.g.maplocalleader = ',';

    -- General settings
    vim.wo.number = true;
    vim.opt.breakindent = false;
    vim.opt.encoding = "utf-8";
    vim.opt.expandtab = true;
    vim.opt.fileencoding = "utf-8";
    vim.opt.hidden = true;
    vim.opt.history = 1000;
    vim.opt.ignorecase = true;
    vim.opt.shiftwidth = 2;
    vim.opt.showmode = true;
    vim.opt.showtabline = 2;
    vim.opt.smartindent = true;
    vim.opt.softtabstop = 2;
    vim.opt.tabstop = 2;
    vim.opt.termguicolors = true;
    vim.opt.timeoutlen = 1000;
    vim.opt.wrap = false;
    
    -- Disable all swap files
    vim.opt.swapfile = false;

    -- Option that lets copy and paste work with system without special clipboard named "+
    vim.api.nvim_set_option("clipboard", "unnamedplus")

    -- Add helper functions at the top for other lua sections to use
    local function keymap(key, action)
      vim.keymap.set("n", key, action, { silent = true, noremap = false })
    end

    local function nkeymap(key, action)
      vim.keymap.set("n", key, action, { silent = true, noremap = true })
    end

    -- Terminal Keys
    local function tkeymap(key, action)
      vim.keymap.set("t", key, action, { silent = true, noremap = true })
    end
  '';
in
{
  imports = [
    ./theme
    ./tools
    ./lsp

    ./keymaps.nix
  ];

  lua = initialLua;
}

