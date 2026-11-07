{ debug, pkgs, ... }:

let
  name = "tools";

  #treesitter-ensured-list = debug.traceResult (
  #  builtins.concatStringsSep "," (map (f: "\"${f}\"") treesitter-parsers)
  #);

  lua = debug.traceResult /* lua */ ''
    require("lualine").setup({
      options = {
        icons_enabled = true
      },
      sections = {
        lualine_x = {
          {
            function()
              return _G.nixvim_debugging and _G.nixvim_debugging.helpers.debug_task_statusline()
                or ""
            end,
            color = function()
              return _G.nixvim_debugging and (_G.nixvim_debugging.helpers.debug_task_statusline_color() or {})
                or {}
            end,
          },
          {
            function()
              return _G.nix_env and _G.nix_env.statusline() or ""
            end,
            color = function()
              return _G.nix_env and (_G.nix_env.statusline_color() or {}) or {}
            end,
          },
          'encoding',
          'fileformat',
          'filetype',
        },
      },
    })
    require("luasnip").config.set_config({})

    -- require('bufferline').setup({
    --   options = {
    --     hover = {
    --       enabled = false
    --     }
    --   }
    -- })

    local commentApi = require('Comment.api')
    local commentVvar = vim.api.nvim_get_vvar

    nkeymapd("<leader>kc", "Comment current line", commentApi.comment.linewise.current)
    nkeymapd("<leader>ku", "Uncomment current line", commentApi.uncomment.linewise.current)
    vkeymapd("<leader>kc", "Toggle comment on selection", '<Plug>(comment_toggle_linewise_visual)')
    vkeymapd("<leader>ku", "Toggle comment on selection", '<Plug>(comment_toggle_linewise_visual)')
  '';
in
{
  inherit name lua;

  imports = [
    ./noice.nix
    ./snacks.nix

    ./bqf.nix
    ./coverage.nix

    ./db.nix

    ./debugging
    ./project-extensions.nix
    ./testing.nix

    ./bookmarks.nix

    ./electronics
  ];

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
    in
    [
      comment-nvim
    ]
    ++ (with pkgs.vimPlugins; [
      lualine-nvim
      lualine-lsp-progress

      luasnip

      bufferline-nvim

      # This tool gives the ability to see inline git changes
      gitsigns-nvim
    ]);

}
