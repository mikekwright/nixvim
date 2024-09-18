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

    require('gitsigns').setup({
      signs = {
        add          = { text = '┃' },
        change       = { text = '┃' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
        untracked    = { text = '┆' },
      },
      signs_staged = {
        add          = { text = '┃' },
        change       = { text = '┃' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
        untracked    = { text = '┆' },
      },
      signs_staged_enable = true,
      signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
      numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
      linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
      word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
      watch_gitdir = {
        follow_files = true
      },
      auto_attach = true,
      attach_to_untracked = false,
      current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
        delay = 1000,
        ignore_whitespace = false,
        virt_text_priority = 100,
        use_focus = true,
      },
      current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
      sign_priority = 6,
      update_debounce = 100,
      status_formatter = nil, -- Use default
      max_file_length = 40000, -- Disable if file is longer than this (in lines)
      preview_config = {
        -- Options passed to nvim_open_win
        border = 'single',
        style = 'minimal',
        relative = 'cursor',
        row = 0,
        col = 1
      },

      on_attach = function(bufnr)
        local gitsigns = require('gitsigns')

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal({']c', bang = true})
          else
            gitsigns.nav_hunk('next')
          end
        end)

        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal({'[c', bang = true})
          else
            gitsigns.nav_hunk('prev')
          end
        end)

        -- Actions
        map('n', '<leader>hs', gitsigns.stage_hunk)
        map('n', '<leader>hr', gitsigns.reset_hunk)
        map('v', '<leader>hs', function() gitsigns.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
        map('v', '<leader>hr', function() gitsigns.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
        map('n', '<leader>hS', gitsigns.stage_buffer)
        map('n', '<leader>hu', gitsigns.undo_stage_hunk)
        map('n', '<leader>hR', gitsigns.reset_buffer)
        map('n', '<leader>hp', gitsigns.preview_hunk)
        map('n', '<leader>hb', function() gitsigns.blame_line{full=true} end)
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame)
        map('n', '<leader>hd', gitsigns.diffthis)
        map('n', '<leader>hD', function() gitsigns.diffthis('~') end)
        map('n', '<leader>td', gitsigns.toggle_deleted)

        -- Text object
        map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
      end
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
    ./tree.nix
    ./noice.nix
    ./left-status.nix
    ./db-tools.nix
    ./telescope.nix
    ./copilot.nix
    ./debugging.nix
    ./testing.nix
    ./whichkey.nix
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

