{ pkgs, ... }:

let
  luaConfig = /*lua*/ ''
    -- While the below works for normal mode, it does not work for visual mode at this time
    --    I am just going to use the nixvim setup for defining the keys for toggle
    local commentApi = require('Comment.api')
    local commentVvar = vim.api.nvim_get_vvar

    local commentKey = "<leader>kc"
    local uncommentKey = "<leader>ku"

    --vim.keymap.set("n", "<leader>kc", commentApi.comment.linewise.current, { silent = true, noremap = true })

    -- NORMAL mode mappings
    --vim.keymap.set('n', commentKey, '<Plug>(comment_comment_linewise)', { desc = 'Comment toggle linewise' })
    --vim.keymap.set('n', cfg.opleader.block, '<Plug>(comment_comment_blockwise)', { desc = 'Comment toggle blockwise' })

    --vim.keymap.set('n', commentKey, function()
    --    return commentVvar('count') == 0 and '<Plug>(comment_comment_linewise_current)'
    --        or '<Plug>(comment_comment_linewise_count)'
    --end, { expr = true, desc = 'Comment toggle current line' })

    -- vim.keymap.set('n', commentKey, function()
    --     return vvar('count') == 0 and '<Plug>(comment_toggle_blockwise_current)'
    --         or '<Plug>(comment_toggle_blockwise_count)'
    -- end, { expr = true, desc = 'Comment toggle current block' })

    -- VISUAL mode mappings
    --vim.keymap.set('x', commentKey, '<Plug>(comment_comment_linewise_visual)', { desc = 'Comment toggle linewise (visual)' })
    --vim.keymap.set('v', commentKey, '<Plug>(comment_comment_linewise_visual)', { desc = 'Comment toggle linewise (visual)' })
    -- K(
    --     'x',
    --     cfg.opleader.block,
    --     '<Plug>(comment_toggle_blockwise_visual)',
    --     { desc = 'Comment toggle blockwise (visual)' }
    -- )

    
    --commentApi = require("Comment.api")
    vim.keymap.set("n", "<leader>kc", commentApi.comment.linewise.current, { silent = true, noremap = true })
    vim.keymap.set("n", "<leader>ku", commentApi.uncomment.linewise.current, { silent = true, noremap = true })
    vim.keymap.set("v", "<leader>kc", '<Plug>(comment_toggle_linewise_visual)', { silent = true, noremap = true })
    vim.keymap.set("v", "<leader>ku", '<Plug>(comment_toggle_linewise_visual)', { silent = true, noremap = true })


    --vim.keymap.set("v", "<leader>kc", function()
        -- vim.api.nvim_feedkeys(esc, 'nx', false)
    --    commentApi.comment.linewise(vim.fn.visualmode())
    --end, { silent = true, noremap = true })
    -- vim.keymap.set("v", "<leader>ku", commentApi.uncomment.linewise(vim.fn.visualmode()), { silent = true, noremap = true })
  '';
in
{
  extraConfigLua = luaConfig;

  plugins.comment = {
    enable = true;
  };
}

