{ ... }:

let
  keysLua = /*lua*/ ''
    -- Easily toggle between relative number showing
    nkeymapd("<leader>r", "Toggle relative line numbers", function()
      vim.wo.relativenumber = not vim.wo.relativenumber
    end)

    tkeymapd("<C-w>h", "Terminal: Focus window left", "<C-\\><C-n><C-w>h")
    tkeymapd("<C-w>j", "Terminal: Focus window below", "<C-\\><C-n><C-w>j")
    tkeymapd("<C-w>k", "Terminal: Focus window above", "<C-\\><C-n><C-w>k")
    tkeymapd("<C-w>l", "Terminal: Focus window right", "<C-\\><C-n><C-w>l")
    tkeymapd("<C-w>n", "Terminal: Next buffer", "<C-\\><C-n>:bnext<CR>")
    tkeymapd("<C-w>p", "Terminal: Previous buffer", "<C-\\><C-n>:bprevious<CR>")
    tkeymapd("<C-t>", "Terminal: Leave insert mode", "<C-\\><C-n>")
    keymapd("<C-w>n", "Next buffer", ":bnext<CR>")
    keymapd("<C-w>p", "Previous buffer", ":bprevious<CR>")

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

