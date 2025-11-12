{pkgs, options, ...}: let
  markdownLua =
    /*
    lua
    */
    ''
      local markdownPlugin = require('render-markdown')
      markdownPlugin.setup({})

      --- More commands can be configured (https://github.com/MeanderingProgrammer/render-markdown.nvim?tab=readme-ov-file#commands)
      keymapd("<leader>lem", "LSP: Toggle Markdown rendering", markdownPlugin.toggle)
    '';
in {
  lua = options.extensions "lsp.markdown" markdownLua;

  vimPackages = with pkgs.vimPlugins; options.extensions "lsp.markdown" [
    render-markdown-nvim
    mini-nvim
    nvim-treesitter
  ];

  packages = with pkgs; options.packages "lsp.markdown" [
    markdownlint-cli
  ];
}
