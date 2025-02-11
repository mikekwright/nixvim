{ pkgs, ... }:

let
  toggle-config = builtins.readFile ./snacks/toggle.lua;
  picker-config = builtins.readFile ./snacks/picker.lua;
  animate-config = builtins.readFile ./snacks/animate.lua;
  bigfile-config = builtins.readFile ./snacks/bigfile.lua;
  dim-config = builtins.readFile ./snacks/dim.lua;
  gitbrowse-config = builtins.readFile ./snacks/gitbrowse.lua;

  snacks-lua = /*lua*/ ''
    snacks = require('snacks')
    snacks.setup({
      toggle = ${toggle-config},
      picker = ${picker-config},
      animate = ${animate-config},
      bigfile = ${bigfile-config},

      -- This is the plugin that will dim areas that are not in focus on the code (goes by clock)
      dim = ${dim-config},
      gitbrowse = ${gitbrowse-config},

      -- This field requires the lazy module (which I am not using)
      -- dashboard = ,
    })

    --
    -- The which key group configuration for Snacks
    --
    wk.add({
      { "<leader>s", group = "Snacks" },
      { "<leader>sd", group = "Code Dim" },
      { "<leader>sg", group = "Git" },
    })


    -- Buffer Delete keyboard shortcuts
    keymapd("<leader>bd", "Delete current buffer", function()
      snacks.bufdelete()
    end)

    -- Dim keyboard shortcuts
    local initialized_dim = false
    keymapd("<leader>sde", "Enable the Dim feature", function()
      if not initialized_dim then
        snacks.dim()
        initialized_dim = true
      end
      snacks.dim.enable()
    end)
    keymapd("<leader>sdd", "Disable the Dim feature", function()
      snacks.dim.disable()
    end)

    -- Gitbrowse file view
    keymapd("<leader>sgv", "View the file in github", function()
      snacks.gitbrowse()
    end)

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
    sqlite
  ];
}
