{ pkgs, ... }:

let
  luaConfig = /*lua*/ ''
    local function keymap(key, action)
      vim.keymap.set("n", key, action, { silent = true, noremap = false })
    end

    local function nkeymap(key, action)
      vim.keymap.set("n", key, action, { silent = true, noremap = true })
    end


    -- Easily toggle between relative number showing
    nkeymap("<leader>r", function()
      vim.wo.relativenumber = not vim.wo.relativenumber
    end)

    --
    -- This is just an example till a useful one emerges
    --
    --local treeApi = require("nvim-tree.api")
    --nkeymap("<leader>e", treeApi.tree.toggle)

    -- Terminal Keys
    local function tkeymap(key, action)
      vim.keymap.set("t", key, action, { silent = true, noremap = true })
    end

    tkeymap("<C-w>h", "<C-\\><C-n><C-w>h")
    tkeymap("<C-w>j", "<C-\\><C-n><C-w>j")
    tkeymap("<C-w>k", "<C-\\><C-n><C-w>k")
    tkeymap("<C-w>l", "<C-\\><C-n><C-w>l")
    tkeymap("<C-t>", "<C-\\><C-n>")

    keymap("<C-t>", ":new<CR>:terminal<CR>i")  -- The extra i should put it in insert mode for the terminal

    -- Tab is not supported in neovim by default, this maps to insert mode flow
    --vim.keymap.set("n", "<TAB>", ">>")
    --vim.keymap.set("n", "<S-TAB>", "<<")
  '';

  keymap = key: action: {
    mode = "n";
    key = key;
    action = action;
    options.silent = true;
  };

  nkeymap = key: action: {
    mode = "n";
    key = key;
    action = action;
    options = {
      silent = true;
      noremap = true;
    };
  };
in
{
  extraConfigLua = luaConfig;

  globals.mapleader = ",";

  keymaps = [
    # General shortcuts
    (nkeymap "<leader>fm" "<cmd>Man<CR>")

    # Tree keyboard shortcuts
    (nkeymap "<leader>e" ":NvimTreeToggle<CR>")

    # Window navigation shortcuts
    (nkeymap "<C-h>" ":help lua-guide<CR>")
    #(nkeymap "<C-j>" "<C-w>j")
    #(nkeymap "<C-k>" "<C-w>k")
    #(nkeymap "<C-l>" "<C-w>l")

    # Window sizing helpders
    #(nkeymap "<C-r>h" ":resize -2<CR>")
    #(nkeymap "<C-r>l" ":resize +2<CR>")
    #(nkeymap "<C-r>j" ":vertical resize -2<CR>")
    #(nkeymap "<C-r>k" ":vertical resize +2<CR>")
  ];
}

