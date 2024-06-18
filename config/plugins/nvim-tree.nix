{ ... }:

let
  nvimtree-lua = (builtins.readFile ./lua/nvim-tree.lua);
in
{
  # Options: https://github.com/nix-community/nixvim/blob/main/plugins/filetrees/nvim-tree.nix
  plugins.nvim-tree = {
    enable = true;
    openOnSetup = true;
    autoClose = true;
    actions = {
      windowPicker.enable = false;
    };

    onAttach.__raw = ''
      function(bufnr)
        nvimTreeOnAttach(bufnr)
      end
    '';
    #onAttach = {
    #  __raw = ''
    #    function()
    #      local api = require("nvim-tree.api")
    #      vim.keymap.set("n", "s", api.node.open.vertical, {})

    #      vim.keymap.set("n", "<leader>e", api.tree.toggle, {})
    #      vim.keymap.set("n", "<C-P>", api.tree.toggle, {})
    #    end
    #  '';
    #};
  };

  extraConfigLua = nvimtree-lua;
}

