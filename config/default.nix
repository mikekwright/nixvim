{ pkgs, ... }:

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
    vim.opt.fileencoding = "utf-8";
    vim.opt.hidden = true;
    vim.opt.history = 1000;

    -- Correct search support (ignore case, unless search includes case)
    vim.opt.ignorecase = true;
    vim.opt.smartcase = true;

    vim.opt.shiftwidth = 2;
    vim.opt.showmode = true;
    vim.opt.showtabline = 2;
    vim.opt.smartindent = true;

    vim.opt.expandtab = true;
    vim.opt.softtabstop = 2;
    vim.opt.tabstop = 2;

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

    -- Visual mode keys
    function xkeymapd(key, desc, action)
      vim.keymap.set("x", key, action, { silent = true, noremap = true, desc = desc})
    end
    function vkeymapd(key, desc, action)
      vim.keymap.set("v", key, action, { silent = true, noremap = true, desc = desc})
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

    -- Changes for jumplist (:help jumplist)
    keymapd("<leader>gb", "Goto: Previous Location", "<C-O>")

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
  imports = [
    ./theme
    ./tools
    ./lsp

    ./keymaps.nix
    ./greeter.nix
  ];

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
    nvim-nio
  ] ++ (with pkgs.vimPlugins; [
    # Set of many different lua functions that you can take advantage of as needed instead of
    #   reinventing the wheel on your own implementations
    # https://github.com/nvim-lua/plenary.nvim/
    plenary-nvim
  ]);
}
