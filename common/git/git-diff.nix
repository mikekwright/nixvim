{ pkgs, ... }:

let

  diffview-lua = /*lua*/ ''
    wk.add({
      { "<leader>eg", group = "Explore git", desc = "Tools for working with git" },
      { "<leader>egs", group = "Git staging", desc = "Git diff tools" },
    })

    keymapd("<leader>egd", "Open git diff view", ":DiffviewOpen<CR>")
    keymapd("<leader>egc", "Close git view", ":DiffviewClose<CR>")
    keymapd("<leader>egv", "Open git history viewer", ":DiffviewFileHistory<CR>")
    keymapd("<leader>egf", "View git file history", ":DiffviewFileHistory %<CR>")
    xkeymapd("<leader>egv", "Show git history", ":'<,'>DiffviewFileHistory<CR>")
  '';
in
{
  lua = diffview-lua;

  vimPackages = with pkgs.vimPlugins; [
    diffview-nvim
  ];
}
