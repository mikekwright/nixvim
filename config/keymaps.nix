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

in
{
  globals.mapleader = ",";

  keymaps = [
    (nkeymap "<leader>e" ":NvimTreeToggle <CR>")
  ];

  extraConfigLua = ''
    local function keymap(key, action)
      vim.keymap.set("n", key, action, { silent = true, noremap = false })
    end

    local function nkeymap(key, action)
      vim.keymap.set("n", key, action, { silent = true, noremap = true })
    end

    --
    -- This is just an example till a useful one emerges
    --
    --local treeApi = require("nvim-tree.api")
    --nkeymap("<leader>e", treeApi.tree.toggle)
  '';
}

