{ pkgs, ... }:

# This file contains the plugin support for winshift that allows for window movement
#   https://github.com/sindrets/winshift.nvim
let
  luaConfig = /*lua*/ ''
    -- Lua
    --   (This is the initial config provided by the repo, small adjustments were made)

    local function setupWinshift()
      require("winshift").setup({
        highlight_moving_win = true,  -- Highlight the window being moved
        focused_hl_group = "Visual",  -- The highlight group used for the moving window
        moving_win_options = {
          -- These are local options applied to the moving window while it's
          -- being moved. They are unset when you leave Win-Move mode.
          wrap = false,
          cursorline = false,
          cursorcolumn = false,
          colorcolumn = "",
        },
        keymaps = {
          disable_defaults = false, -- Disable the default keymaps
          win_move_mode = {
            ["h"] = "left",
            ["j"] = "down",
            ["k"] = "up",
            ["l"] = "right",
            ["H"] = "far_left",
            ["J"] = "far_down",
            ["K"] = "far_up",
            ["L"] = "far_right",
            ["<left>"] = "left",
            ["<down>"] = "down",
            ["<up>"] = "up",
            ["<right>"] = "right",
            ["<S-left>"] = "far_left",
            ["<S-down>"] = "far_down",
            ["<S-up>"] = "far_up",
            ["<S-right>"] = "far_right",
          },
        },
        ---A function that should prompt the user to select a window.
        ---
        ---The window picker is used to select a window while swapping windows with
        ---`:WinShift swap`.
        ---@return integer? winid # Either the selected window ID, or `nil` to
        ---   indicate that the user cancelled / gave an invalid selection.
        window_picker = function()
          return require("winshift.lib").pick_window({
            -- A string of chars used as identifiers by the window picker.
            picker_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
            filter_rules = {
              -- This table allows you to indicate to the window picker that a window
              -- should be ignored if its buffer matches any of the following criteria.
              cur_win = true, -- Filter out the current window
              floats = true,  -- Filter out floating windows
              filetype = {},  -- List of ignored file types
              buftype = {},   -- List of ignored buftypes
              bufname = {},   -- List of vim regex patterns matching ignored buffer names
            },
            ---A function used to filter the list of selectable windows.
            ---@param winids integer[] # The list of selectable window IDs.
            ---@return integer[] filtered # The filtered list of window IDs.
            filter_func = nil,
          })
        end,
      })

      -- Start Win-Move mode:
      vim.keymap.set("n", "<C-W>m", "<Cmd>WinShift<CR>", { silent = true, noremap = true })
      vim.keymap.set("n", "<C-W>H", "<Cmd>WinShift left<CR>", { silent = true, noremap = true })
      vim.keymap.set("n", "<C-W>J", "<Cmd>WinShift down<CR>", { silent = true, noremap = true })
      vim.keymap.set("n", "<C-W>K", "<Cmd>WinShift up<CR>", { silent = true, noremap = true })
      vim.keymap.set("n", "<C-W>L", "<Cmd>WinShift right<CR>", { silent = true, noremap = true })
      -- Swap two windows:
      --nnoremap <C-W>X <Cmd>WinShift swap<CR>
    end
  '';
in
{
  extraPackages = with pkgs.vimPlugins; [
    winshift-nvim
  ];

  extraConfigLua = luaConfig;
}

