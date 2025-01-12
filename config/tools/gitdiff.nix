{ extra-pkgs, ... }:

let

  diffview-lua = /*lua*/ ''
    keymapd("<leader>gd", ":DiffviewOpen<CR>", "Open git diff view")
    keymapd("<leader>gc", ":DiffviewClose<CR>", "Close git view")
    keymapd("<leader>gv", ":DiffviewFileHistory<CR>", "Open git history viewer")
    keymapd("<leader>gf", ":DiffviewFileHistory %<CR>", "View git file history")
    xkeymapd("<leader>gv", ":'<,'>DiffviewFileHistory<CR>", "Show git history")
  '';
in
{
  lua = diffview-lua;

  vimPackages = with extra-pkgs.diffview-pkgs.vimPlugins; [
    diffview-nvim
  ];
}
