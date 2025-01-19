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
    tkeymap("<C-t>", "<C-\\><C-n>")

    -- This key opens a new terminal
    keymap("<C-t>", ":new<CR>:terminal<CR>i")  -- The extra i should put it in insert mode for the terminal
    keymapd("<leader>tt", "Open terminal", ":new<CR>:terminal<CR>i")

    keymapd("<leader>cs", "Clear search highlights", ":nohlsearch<CR>")

    keymapd("<leader>qa", "Quit all", ":qall<CR>")
    keymapd("<leader>qq", "Quit all (forced)", ":qall!<CR>")

    keymapd("<leader>gg", "Go to help section", "<C-]>")

    -- Tab is not supported in neovim by default, this maps to insert mode flow
    --vim.keymap.set("n", "<TAB>", ">>")
    --vim.keymap.set("n", "<S-TAB>", "<<")
  '';
in
{
  lua = keysLua;
}

