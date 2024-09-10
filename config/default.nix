{ ... }:

let
  initialLua = /*lua*/ ''
    -- As we are trying to optimize our solution for just config defined in this flake we need
    --    to have our system ignore default configs
    vim.opt.runtimepath:remove(vim.fn.stdpath('config'))              -- ~/.config/nvim
    vim.opt.runtimepath:remove(vim.fn.stdpath('config') .. "/after")  -- ~/.config/nvim/after
    vim.opt.runtimepath:remove(vim.fn.stdpath('data') .. "/site")     -- ~/.local/share/nvim/site

    -- disable netrw at the very start of your init.lua
    vim.g.loaded_netrw = 1;
    vim.g.loaded_netrwPlugin = 1;

    -- Set the leader key
    vim.g.mapleader = ',';
    vim.g.maplocalleader = ',';

    vim.wo.number = true;

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

