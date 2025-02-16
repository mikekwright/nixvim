{ debug, pkgs, ... }:

let
  #treesitter-ensured-list = debug.traceResult (
  #  builtins.concatStringsSep "," (map (f: "\"${f}\"") treesitter-parsers)
  #);

  tools-setup-lua = /*lua*/ ''
    require("lualine").setup({
      options = {
        icons_enabled = true
      }
    })
    require("luasnip").config.set_config({})

    require('bufferline').setup({
      options = {
        hover = {
          enabled = false
        }
      }
    })

    local commentApi = require('Comment.api')
    local commentVvar = vim.api.nvim_get_vvar

    nkeymap("<leader>kc", commentApi.comment.linewise.current)
    nkeymap("<leader>ku", commentApi.uncomment.linewise.current)
    vim.keymap.set("v", "<leader>kc", '<Plug>(comment_toggle_linewise_visual)', { silent = true, noremap = true })
    vim.keymap.set("v", "<leader>ku", '<Plug>(comment_toggle_linewise_visual)', { silent = true, noremap = true })
  '';
in
{
  name = "tools";

  imports = [
    ./whichkey.nix
    ./tree.nix
    ./noice.nix
    ./left-status.nix
    ./db-tools.nix

    ./debugging.nix
    ./testing.nix
    ./bookmarks.nix
    ./gitdiff.nix
    #./gitsigns.nix
    ./bqf.nix

    ./snacks.nix
  ];

  lua = debug.traceResult tools-setup-lua;

  packages = with pkgs; [
    lazygit
  ];

  vimPackages =
    let
      comment-nvim = pkgs.vimUtils.buildVimPlugin {
        name = "comment.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "numToStr";
          repo = "Comment.nvim";
          rev = "e30b7f2008e52442154b66f7c519bfd2f1e32acb";
          sha256 = "h0kPue5Eqd5aeu4VoLH45pF0DmWWo1d8SnLICSQ63zc=";
        };
      };
    in [
      comment-nvim
    ] ++ (with pkgs.vimPlugins; [
      lualine-nvim
      lualine-lsp-progress

      luasnip

      bufferline-nvim

      # This tool gives the ability to see inline git changes
      gitsigns-nvim
    ]);

}

