{ pkgs, ... }:

let
  # Read more from documentation
  #  https://github.com/folke/snacks.nvim/blob/main/docs/util.md

  
  # How to animate things that take place in neovim
  animate = (import ./snacks/animate.nix) { inherit pkgs; };

  # Helps to stop loading really large files
  blameline = (import ./snacks/blame-line.nix) { inherit pkgs; };

  # Zen is the mode that gives you focus on the area you want to work in.
  zen = (import ./snacks/zen.nix) { inherit pkgs; };

  # Helper to open a floating window with the history of the current file
  bigfile = (import ./snacks/bigfile.nix) { inherit pkgs; };

  # This is the plugin that will dim areas that are not in focus on the code (goes by clock)
  dim = (import ./snacks/dim.nix) { inherit pkgs; };

  # Quick solution to create a url that will open the current file in the source host url
  gitbrowse = (import ./snacks/gitbrowse.nix) { inherit pkgs; };

  # Provides a simple and useful indent marker that you can turn on/off and configure
  indent = (import ./snacks/indent.nix) { inherit pkgs; };

  # This is the big one, a replacement for the telescope plugin but provides all
  #   the same functionality, just built into the same solution
  picker = (import ./snacks/picker.nix) { inherit pkgs; };

  toggle = (import ./snacks/toggle.nix) { inherit pkgs; };

  words = (import ./snacks/words.nix) { inherit pkgs; };

  snacks-lua = /*lua*/ ''
    snacks = require('snacks')
    snacks.setup({
      toggle = ${toggle.config},
      picker = ${picker.config},
      animate = ${animate.config},
      bigfile = ${bigfile.config},
      dim = ${dim.config},
      gitbrowse = ${gitbrowse.config},
      blame_line = ${blameline.config},
      indent = ${indent.config},
      zen = ${zen.config},
      words = ${words.config},
    })

    --
    -- The which key group configuration for Snacks
    --
    -- wk.add({
    --   { "<leader>s", group = "Snacks" },
    --   { "<leader>sd", group = "Code Dim" },
    --   { "<leader>sg", group = "Git" },
    --   { "<leader>sv", group = "View Options" },
    --   { "<leader>svi", group = "Indent Option" },
    -- })

    -- Buffer Delete keyboard shortcuts
    keymapd("<leader>bd", "Delete current buffer", function()
      snacks.bufdelete()
    end)

    ${animate.keymaps}
    ${indent.keymaps}
    ${blameline.keymaps}
    ${dim.keymaps}
    ${gitbrowse.keymaps}
    ${bigfile.keymaps}
    ${picker.keymaps}
    ${zen.keymaps}
    ${toggle.keymaps}
    ${words.keymaps}
  '';
in
{
  lua = snacks-lua;

  vimPackages = let
    snacks-nvim = pkgs.vimUtils.buildVimPlugin {
      name = "snacks-nvim";
      src = pkgs.fetchFromGitHub {
        owner = "folke";
        repo = "snacks.nvim";
        rev = "v2.20.0";
        sha256 = "YUjTuY47fWnHd9/z6WqFD0biW+wn9zLLsOVJibwpgKw=";
      };
    };
  in [
    snacks-nvim
  ] ++ (with pkgs.vimPlugins; [
    sqlite-lua
  ]);

  packages = with pkgs; [
    # Snacks searcher uses rg
    ripgrep
    sqlite
  ];
}
