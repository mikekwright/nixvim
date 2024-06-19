
local function keymap(key, action)
  vim.keymap.set("n", key, action, { silent = true, noremap = false })
end

local function nkeymap(key, action)
  vim.keymap.set("n", key, action, { silent = true, noremap = true })
end


-- Easily toggle between relative number showing
nkeymap("<leader>r", function()
  vim.wo.relativenumber = not vim.wo.relativenumber
end)

--
-- This is just an example till a useful one emerges
--
--local treeApi = require("nvim-tree.api")
--nkeymap("<leader>e", treeApi.tree.toggle)

-- Terminal Keys
local function tkeymap(key, action)
  vim.keymap.set("t", key, action, { silent = true, noremap = true })
end

tkeymap("<C-w>h", "<C-\\><C-n><C-w>h")
tkeymap("<C-w>j", "<C-\\><C-n><C-w>j")
tkeymap("<C-w>k", "<C-\\><C-n><C-w>k")
tkeymap("<C-w>l", "<C-\\><C-n><C-w>l")
tkeymap("<C-t>", "<C-\\><C-n>")

keymap("<C-t>", ":new<CR>:terminal<CR>i")  -- The extra i should put it in insert mode for the terminal

