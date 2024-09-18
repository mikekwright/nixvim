{extra-pkgs, ...}: let
  markdownLua =
    /*
    lua
    */
    ''
      local markdownPlugin = require('render-markdown')
      markdownPlugin.setup({})

      --- More commands can be configured (https://github.com/MeanderingProgrammer/render-markdown.nvim?tab=readme-ov-file#commands)
      keymapd("<leader>lmd", markdownPlugin.disable, "Disable markdown rendering")
      keymapd("<leader>lme", markdownPlugin.enable, "Enable markdown rendering")
    '';
in {
  lua = markdownLua;

  vimPackages =
    (with extra-pkgs.markdown-pkgs.vimPlugins; [
      render-markdown
      mini-nvim
    ])
    ++ (with extra-pkgs.nvim-treesitter-pkgs.vimPlugins; [
      nvim-treesitter
    ]);
}
