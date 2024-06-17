
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

