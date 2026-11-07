{ pkgs, ... }:

let
  diffview-lua = /*lua*/ ''
    wk.add({
      { "<leader>gs", group = "Git staging", desc = "Stage, reset and preview hunks" },
    })

    keymapd("<leader>gd", "Open git diff view", ":DiffviewOpen<CR>")
    keymapd("<leader>gc", "Close git view", ":DiffviewClose<CR>")
    keymapd("<leader>gv", "Open git history viewer", ":DiffviewFileHistory<CR>")
    keymapd("<leader>gf", "View git file history", ":DiffviewFileHistory %<CR>")
    xkeymapd("<leader>gv", "Show git history", ":'<,'>DiffviewFileHistory<CR>")
  '';
in
{
  common = true;

  lua = diffview-lua;

  vimPackages = with pkgs.vimPlugins; [
    diffview-nvim
  ];
}
