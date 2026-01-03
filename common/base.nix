{ pkgs, ... }:

let
  initialLua = /*lua*/ ''
    -- The below requires the snacks plugin to be for the functions to work, but if so it can help with some
    -- debug views
    _G.dd = function(...)
      require('snacks').debug.inspect(...)
    end
    _G.bt = function()
      require('snacks').debug.backtrace()
    end
    --vim.print = _G.dd

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
    vim.opt.fileencoding = "utf-8";
    vim.opt.hidden = true;
    vim.opt.history = 1000;

    -- Correct search support (ignore case, unless search includes case)
    vim.opt.ignorecase = true;
    vim.opt.smartcase = true;

    vim.opt.shiftwidth = 2;
    vim.opt.showmode = true;

    -- This option should disable the tab name that shows at the top (when value is 0)
    vim.opt.showtabline = 1;

    -- Better handling of the indent flow
    vim.opt.smartindent = true;
    vim.opt.expandtab = true;
    vim.opt.softtabstop = 2;
    vim.opt.tabstop = 2;

    -- Make sure we are always in a dark setup
    vim.opt.termguicolors = true;
    vim.opt.background = "dark";

    --   This can be useful to turn on if we are having some odd issues with the screen moving a lot
    --   with the left side jumping on and off (like with gitsign)
    -- vim.opt.signcolumn = "yes";

    vim.opt.backspace = "indent,eol,start";
    vim.opt.timeoutlen = 1000;
    vim.opt.wrap = false;
    
    -- Disable all swap files
    vim.opt.swapfile = false;

    -- Option that lets copy and paste work with system without special clipboard named "+
    vim.api.nvim_set_option("clipboard", "unnamedplus")

    function keymap(key, action)
      vim.keymap.set("n", key, action, { silent = true, noremap = false })
    end
    function keymapd(key, desc, action)
      vim.keymap.set("n", key, action, { silent = true, noremap = false, desc = desc })
    end

    function nkeymap(key, action)
      vim.keymap.set("n", key, action, { silent = true, noremap = true })
    end

    -- Terminal Keys
    function tkeymap(key, action)
      vim.keymap.set("t", key, action, { silent = true, noremap = true })
    end
    function tkeymapd(key, desc, action)
      vim.keymap.set("t", key, action, { silent = true, noremap = true, desc = desc })
    end

    -- Visual mode keys
    function xkeymapd(key, desc, action)
      vim.keymap.set("x", key, action, { silent = true, noremap = true, desc = desc})
    end
    function vkeymapd(key, desc, action)
      vim.keymap.set("v", key, action, { silent = true, noremap = true, desc = desc})
    end

    -- Insert mode keys
    function ikeymapd(key, desc, action)
      vim.keymap.set("i", key, action, { silent = true, noremap = true, desc = desc})
    end

    local run_in_debug = false
    function dprint(msg)
      if run_in_debug then
        print(msg)
      end
    end

    nkeymap("<leader>qd", function()
      run_in_debug = not run_in_debug
      print("Custom debugging is now: " .. tostring(run_in_debug))
    end)

    -- Reload current buffer from disk
    keymapd("<leader>er", "Reload buffer from disk", ":e<CR>")
    keymapd("<leader>bh", "Hide the current buffer", ":hide<CR>")
    keymapd("<leader>bn", "Next buffer", ":bnext<CR>")
    keymapd("<leader>bp", "Previous buffer", ":bprevious<CR>")
    keymapd("<leader>bd", "Delete current buffer", ":bdelete<CR>")
    keymapd("<leader>bl", "List buffers", ":ls<CR>")
    keymapd("<leader>bf", "Maximize current buffer", ":only<CR>")

    function print_table(name, t)
      if type(t) == 'table' then
        local s = name .. "{ "
        for k,v in pairs(t) do
           if type(k) ~= 'number' then k = '"'..k..'"' end
           if type(v) ~= 'nil' then v = 'nil' end
           -- s = s .. '['..k..'] = ' .. dump(v) .. ','
           s = s .. '['..k..'] = ' .. v .. ','
        end
        dprint(s .. " }")
      else
        dprint(name .. " is not a table value")
      end
    end
  '';
in
{
  common = true;

  lua = initialLua;

  packages = with pkgs; [
    cloc
  ];

  vimPackages = let
    nvim-nio = pkgs.vimUtils.buildVimPlugin {
      name = "nvim-nio";
      src = pkgs.fetchFromGitHub {
        owner = "nvim-neotest";
        repo = "nvim-nio";
        rev = "v1.10.0";
        sha256 = "i6imNTb1xrfBlaeOyxyIwAZ/+o6ew9C4/z34a7/BgFg=";
      };
    };
  in [
    # nvim-nio
  ] ++ (with pkgs.vimPlugins; [
    # Set of many different lua functions that you can take advantage of as needed instead of
    #   reinventing the wheel on your own implementations
    # https://github.com/nvim-lua/plenary.nvim/
    nvim-nio
    plenary-nvim
  ]);
}
