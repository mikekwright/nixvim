# Telescope provides the fuzzy search features that I enjoy.
{ extra-pkgs, ... }:

let
  telescope-lua-config = /*lua*/ ''
    local telescopeActions = require('telescope.actions')

    require('telescope').setup({
      file_ignore_patterns = {
        "^.git/",
        "^.mypy_cache/",
        "^__pycache__/",
        "^output/",
        "^data/",
        "%.ipynb",
        "^target/",
      },
      set_env = {
        COLORTERM = "truecolor"
      },
      defaults = {
        selection_caret = "> ",
        path_display = { "smart" },
        layout_config = {
          prompt_position = "bottom",
        },
        sorting_strategy = "descending",
        mappings = {
          i = {
            ["<C-k>"] = telescopeActions.move_selection_previous,
            ["<C-j>"] = telescopeActions.move_selection_next,
            ["<C-q>"] = telescopeActions.send_selected_to_qflist + telescopeActions.open_qflist 
          }
        }
      }
    })

    local telescopeBuiltin = require('telescope.builtin')
    nkeymap('<leader>ff', telescopeBuiltin.find_files)
    nkeymap('<C-p>', telescopeBuiltin.find_files)
    nkeymap('<leader>fg', telescopeBuiltin.live_grep)
    nkeymap('<leader>fb', telescopeBuiltin.buffers)
    nkeymap('<leader>fh', telescopeBuiltin.help_tags)

    -- List of possible extensions, but need to be careful to not load too many
    --   https://github.com/nvim-telescope/telescope.nvim/wiki/Extensions
    local telescopeExtensions = require('telescope')
    telescopeExtensions.load_extension('fzf')
  '';
in
{
  lua = telescope-lua-config;

  vimPackages = with extra-pkgs.nvim-telescope-pkgs.vimPlugins; [
    telescope-nvim
    plenary-nvim
    telescope-fzf-native-nvim
  ];

  packages = with extra-pkgs.nvim-telescope-pkgs; [
    fd
    ripgrep
  ];
}
