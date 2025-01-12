{ extra-pkgs, ... }:

let

  diffview-lua = /*lua*/ ''
    keymapd("<leader>gd", "Open git diff view", ":DiffviewOpen<CR>")
    keymapd("<leader>gc", "Close git view", ":DiffviewClose<CR>")
    keymapd("<leader>gv", "Open git history viewer", ":DiffviewFileHistory<CR>")
    keymapd("<leader>gf", "View git file history", ":DiffviewFileHistory %<CR>")
    xkeymapd("<leader>gv", "Show git history", ":'<,'>DiffviewFileHistory<CR>")
  '';
in
{
  lua = diffview-lua;

  vimPackages = with extra-pkgs.diffview-pkgs.vimPlugins; [
    diffview-nvim
  ];
}
