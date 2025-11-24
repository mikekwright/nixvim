{ pkgs, ... }:

let
  diffview-lua = /*lua*/ ''
    wk.add({
      { "<leader>g", group = "Explore git", desc = "Tools for working with git" },
      { "<leader>gs", group = "Git staging", desc = "Git diff tools" },
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
