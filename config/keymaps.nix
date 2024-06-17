{ pkgs, ... }:

let
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

  luaConfig = (builtins.readFile ./lua/keymaps.lua);
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
    (nkeymap "<C-h>" "<C-w>h")
    (nkeymap "<C-j>" "<C-w>j")
    (nkeymap "<C-k>" "<C-w>k")
    (nkeymap "<C-l>" "<C-w>l")

    # Window sizing helpders
    #(nkeymap "<C-r>h" ":resize -2<CR>")
    #(nkeymap "<C-r>l" ":resize +2<CR>")
    #(nkeymap "<C-r>j" ":vertical resize -2<CR>")
    #(nkeymap "<C-r>k" ":vertical resize +2<CR>")
  ];
}

