{pkgs, ...}: let
  name = "lsp.markdown";

  lua = /*lua*/ ''
    local markdownPlugin = require('render-markdown')
    markdownPlugin.setup({})

    --- More commands can be configured (https://github.com/MeanderingProgrammer/render-markdown.nvim?tab=readme-ov-file#commands)
    keymapd("<leader>lem", "LSP: Toggle Markdown rendering", markdownPlugin.toggle)
  '';
in {
  inherit name lua;

  vimPackages = with pkgs.vimPlugins; [
    render-markdown-nvim
    mini-nvim
    nvim-treesitter
  ];

  packages = with pkgs; [
    markdownlint-cli
  ];
}
