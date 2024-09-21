{ pkgs, ... }:

let
  bookmarks_lua = /*lua*/ ''
    require('bookmarks').setup({
      save_file = vim.fn.expand "$HOME/.bookmarks", -- bookmarks save file path
      keywords =  {
        ["@t"] = "☑️ ", -- mark annotation startswith @t ,signs this icon as `Todo`
        ["@w"] = "⚠️ ", -- mark annotation startswith @w ,signs this icon as `Warn`
        ["@f"] = "⛏ ", -- mark annotation startswith @f ,signs this icon as `Fix`
        ["@n"] = "n", -- mark annotation startswith @n ,signs this icon as `Note`
      },
      -- on_attach = function(bufnr)
      --   -- bmtelesceope.load_extension('bookmarks')
      --   --require('bookmarks').on_attach(bufnr)
      -- end
    })

    local bm = require('bookmarks')

    keymapd("<leader>bb", bm.bookmark_toggle, "Bookmark: Toggle Line")
    keymapd("<leader>bi", bm.bookmark_ann, "Bookmark: Add/Edit Annotation")
    keymapd("<leader>bc", bm.bookmark_clean, "Bookmark: Clean All")
    keymapd("<leader>bn", bm.bookmark_next, "Bookmark: Next")
    keymapd("<leader>bp", bm.bookmark_prev, "Bookmark: Previous")
    -- keymapd("<leader>ml", bm.bookmark_list, "Bookmark: List")
    -- keymapd("<leader>ml", bmtelescope.extensions.bookmarks.list, "Bookmark: List (Telescope)")

    -- Remember to setup the telescope extension
    keymapd("<leader>bl", "<cmd>Telescope bookmarks list<cr>", "Bookmark: List (Telescope)")
    keymapd("<leader>bda", bm.bookmark_clear_all, "Bookmark: Clear All")
  '';
in
{
  lua = bookmarks_lua;

  vimPackages = let
    # https://github.com/tomasky/bookmarks.nvim
    bookmark-nvim = pkgs.vimUtils.buildVimPlugin {
      name = "bookmarks.nvim";
      src = pkgs.fetchFromGitHub {
        owner = "tomasky";
        repo = "bookmarks.nvim";
        rev = "0540d52ba64d0ec7677ec1ef14b3624c95a2aaba";
        sha256 = "C6ug5GT1endIOYIomSdBwH9wBUPvnF7hkMNL5+jQ9RA=";
      };
    };
  in [
    bookmark-nvim
  ];
}
