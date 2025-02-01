{ pkgs, ... }:

let
  # This plugin uses the nvim-coverage found on github
  #   https://github.com/andythigpen/nvim-coverage
  coverage-lua = /*lua*/ ''
    require("coverage").setup({
      commands = true, -- create commands
      highlights = {
        -- customize highlight groups created by the plugin
        covered = { fg = "#C3E88D" },   -- supports style, fg, bg, sp (see :h highlight-gui)
        uncovered = { fg = "#F07178" },
      },
      signs = {
        -- use your own highlight groups or text markers
        covered = { hl = "CoverageCovered", text = "▎" },
        uncovered = { hl = "CoverageUncovered", text = "▎" },
      },
      summary = {
        -- customize the summary pop-up
        min_coverage = 80.0,      -- minimum coverage threshold (used for highlighting)
      },
      lang = {
        -- customize language specific settings
      },
    })
  '';
in
{
  lua = coverage-lua;

  vimPackages = with pkgs.vimPlugins; [
    nvim-coverage
  ];
}
