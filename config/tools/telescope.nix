# Telescope provides the fuzzy search features that I enjoy.
{ extra-pkgs, ... }:

let
  telescope-lua-config = /*lua*/ ''
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
      layout_config = {
        prompt_position = "top"
      },
      selection_caret = "> ",
      set_env = {
        COLORTERM = "truecolor"
      },
      sorting_strategy = "ascending"
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
  ];
}
