{ ... }:

let
  keysLua = /*lua*/ ''
    -- Easily toggle between relative number showing
    nkeymap("<leader>r", function()
      vim.wo.relativenumber = not vim.wo.relativenumber
    end)

    tkeymap("<C-w>h", "<C-\\><C-n><C-w>h")
    tkeymap("<C-w>j", "<C-\\><C-n><C-w>j")
    tkeymap("<C-w>k", "<C-\\><C-n><C-w>k")
    tkeymap("<C-w>l", "<C-\\><C-n><C-w>l")
    tkeymap("<C-w>n", "<C-\\><C-n>:bnext<CR>")
    tkeymap("<C-t>", "<C-\\><C-n>")
    keymap("<C-w>n", ":bnext<CR>")

    keymapd("<leader>cs", "Clear search highlights", ":nohlsearch<CR>")

    keymapd("<leader>qa", "Quit all", ":qall<CR>")
    keymapd("<leader>qq", "Quit all (forced)", ":qall!<CR>")

    -- Movement keyboard shortcuts
    keymapd("<leader>mh", "Go to help section", "<C-]>")
    -- Changes for jumplist (:help jumplist)
    keymapd("<leader>mb", "Goto: Previous Location", "<C-O>")

    -- Tab is not supported in neovim by default, this maps to insert mode flow
    --vim.keymap.set("n", "<TAB>", ">>")
    --vim.keymap.set("n", "<S-TAB>", "<<")
  '';
in
{
  common = true;

  lua = keysLua;
}

