{ pkgs, ... }:

let
  name = "tools.bookmarks";

  lua = /*lua*/ ''
    wk.add({
      { "<leader>eb", group = "Bookmarks", desc = "Manage bookmarks" },
    })

    local bm = require('bookmarks')
    bm.setup({
      save_file = vim.fn.expand "$HOME/.bookmarks", -- bookmarks save file path
      keywords =  {
        ["@t"] = "☑️ ", -- mark annotation startswith @t ,signs this icon as `Todo`
        ["@w"] = "⚠️ ", -- mark annotation startswith @w ,signs this icon as `Warn`
        ["@f"] = "⛏ ", -- mark annotation startswith @f ,signs this icon as `Fix`
        ["@n"] = "n", -- mark annotation startswith @n ,signs this icon as `Note`
      },
    })

    keymapd("<leader>mt", "Bookmark: Toggle Line", bm.bookmark_toggle)
    keymapd("<leader>mi", "Bookmark: Add/Edit Annotation", bm.bookmark_ann)

    -- TODO: Convert to a project specific solution, this would likely go outside of your project
    --   and that would be odd.
    -- keymapd("<leader>mn", "Bookmark: Next", bm.bookmark_next)
    -- keymapd("<leader>mp", "Bookmark: Previous", bm.bookmark_prev)

    keymapd("<leader>mC", "Bookmark: Clear All", function()
      local choice = vim.fn.confirm('This will clear all bookmarks for all projects, continue?', '&yes\n&no')

      if choice == 1 then
        bm.bookmark_clear_all()
        vim.print('Cleared all bookmarks for all projects')
      else
        vim.print('Cancelled clear all bookmarks')
      end
    end)

    -- TODO: There is one small issue here, it isn't clearing the bookmark sign for any buffers already open
    keymapd("<leader>mc", "Bookmark: Clean All", function()
      local choice = vim.fn.confirm('This will clear all bookmarks for cwd, continue?', '&yes\n&no')

      if choice == 1 then
        local config = require("bookmarks.config").config
        local allmarks = config.cache.data

        local search_directory = vim.fn.getcwd()
        for filepath, _ in pairs(allmarks) do
          if filepath:sub(1, #search_directory) == search_directory then
            allmarks[filepath] = nil
          end
        end

        config.cache.data = allmarks
        bm.refresh()
        bm.saveBookmarks()
        vim.print('All cwd bookmarks have been cleared')
      else
        vim.print('Cancelled clear cwd bookmarks')
      end
    end)

    local has_snacks,bookmark_snacks = pcall(require,"snacks")
    if has_snacks then
      local config = require("bookmarks.config").config
      local snacks = require("snacks")

      local function get_text(annotation)
        local pref = string.sub(annotation, 1, 2)
        local ret = config.keywords[pref]
        if ret == nil then
          ret = config.signs.ann.text .. " "
        end
        return ret .. annotation
      end

      local function bookmarks_picker()
        local allmarks = config.cache.data
        local items = {}

        local search_directory = vim.fn.getcwd()

        -- Convert bookmarks to list
        for filename, marks in pairs(allmarks) do
          for lnum_str, v in pairs(marks) do

            -- if filename:sub(1, #search_directory) ~= search_directory then
            if filename:find("^" .. vim.pesc(search_directory)) then
              local file_format = string.format("%-40s", filename:match("([^/]+)$") .. ':' .. lnum_str)

              table.insert(items, {
                file = filename,
                pos = tonumber(lnum_str),
                text = file_format .. '  ' .. (v.a and get_text(v.a) or v.m)
              })
            end
          end
        end

        Snacks.picker.pick({
          source = "bookmarks",
          items = items,
          layout = "vscode", -- or "select", "default"
          format = "text",
          title = "Bookmarks",
          confirm = function(picker, item)
            picker:close()
            if item.file then
              vim.cmd("edit " .. item.file)
              if item.pos then
                vim.api.nvim_win_set_cursor(0, {item.pos, 0})
              end
            end
          end,
        })
      end

      keymapd("<leader>ml", "Debug", bookmarks_picker)
    end
  '';
in
{
  inherit lua name;

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
