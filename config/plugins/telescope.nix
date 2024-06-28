{ ... }:

# Telescope is the fuzzy search popup for selecting files, buffers, etc.
let
  luaConfig = /*lua*/ ''
    local telescopeBuiltin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>ff', telescopeBuiltin.find_files, {})
    vim.keymap.set('n', '<C-p>', telescopeBuiltin.find_files, {})
    vim.keymap.set('n', '<leader>fg', telescopeBuiltin.live_grep, {})
    vim.keymap.set('n', '<leader>fb', telescopeBuiltin.buffers, {})
    vim.keymap.set('n', '<leader>fh', telescopeBuiltin.help_tags, {})
  '';
in
{
  extraConfigLua = luaConfig;

  plugins.telescope = {
    enable = true;
    settings = {
      file_ignore_patterns = [
        "^.git/"
        "^.mypy_cache/"
        "^__pycache__/"
        "^output/"
        "^data/"
        "%.ipynb"
      ];
      set_env.COLORTERM = "truecolor";
      sorting_strategy = "ascending";
      selection_caret = "> ";
      layout_config.prompt_position = "top";
      #mappings = {
      #  i = {
      #    "<A-j>".__raw = "require('telescope.actions').move_selection_next";
      #    "<A-k>".__raw = "require('telescope.actions').move_selection_previous";
      #  };
      #}; 
    };
  };
}
