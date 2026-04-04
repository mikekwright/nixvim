{ pkgs, ... }:

let
  name = "lsp.coc";

  lua = /* lua */ ''
    vim.opt.backup = false
    vim.opt.writebackup = false
    vim.opt.updatetime = 300
    vim.opt.signcolumn = "yes"
    vim.opt.completeopt = { "menu", "menuone", "noselect" }

    vim.g.coc_global_extensions = vim.g.coc_global_extensions or {}

    local function ensure_coc_extension(extension)
      if not vim.tbl_contains(vim.g.coc_global_extensions, extension) then
        table.insert(vim.g.coc_global_extensions, extension)
      end
    end

    _G.ensure_coc_extension = ensure_coc_extension

    function _G.coc_merge_config(config)
      vim.g.coc_user_config = vim.tbl_deep_extend('force', vim.g.coc_user_config or {}, config)
    end

    for _, extension in ipairs({ 'coc-snippets', 'coc-nvim-lua' }) do
      ensure_coc_extension(extension)
    end

    _G.coc_backend_enabled = true

    function _G.coc_check_back_space()
      local col = vim.fn.col('.') - 1
      return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
    end

    function _G.coc_show_docs()
      local current_word = vim.fn.expand('<cword>')
      if vim.fn.index({ 'vim', 'help' }, vim.bo.filetype) >= 0 then
        vim.api.nvim_command('h ' .. current_word)
      elseif vim.fn.exists('*CocActionAsync') == 1 then
        vim.fn.CocActionAsync('doHover')
      else
        vim.api.nvim_command('!' .. vim.o.keywordprg .. ' ' .. current_word)
      end
    end

    local expr_opts = { silent = true, noremap = true, expr = true, replace_keycodes = false }
    local map_opts = { silent = true }
    local plug_map_opts = { silent = true, remap = true }

    vim.keymap.set('i', '<Tab>', function()
      if vim.fn['coc#pum#visible']() == 1 then
        return vim.fn['coc#pum#next'](1)
      end

      if not _G.coc_backend_enabled or _G.coc_check_back_space() then
        return '<Tab>'
      end

      return vim.fn['coc#refresh']()
    end, expr_opts)

    vim.keymap.set('i', '<S-Tab>', function()
      if vim.fn['coc#pum#visible']() == 1 then
        return vim.fn['coc#pum#prev'](1)
      end

      return '<C-h>'
    end, expr_opts)

    vim.keymap.set('i', '<C-j>', function()
      if vim.fn['coc#pum#visible']() == 1 then
        return vim.fn['coc#pum#next'](1)
      end

      return '<C-j>'
    end, expr_opts)

    vim.keymap.set('i', '<C-k>', function()
      if vim.fn['coc#pum#visible']() == 1 then
        return vim.fn['coc#pum#prev'](1)
      end

      return '<C-k>'
    end, expr_opts)

    vim.keymap.set('i', '<CR>', function()
      if vim.fn['coc#pum#visible']() == 1 then
        return vim.fn['coc#pum#confirm']()
      end

      return '<C-g>u<CR><c-r>=coc#on_enter()<CR>'
    end, expr_opts)

    vim.keymap.set('i', '<C-Space>', function()
      if not _G.coc_backend_enabled then
        return '<C-Space>'
      end

      return vim.fn['coc#refresh']()
    end, expr_opts)

    vim.keymap.set('i', '<C-l>', function()
      if not _G.coc_backend_enabled then
        return '<C-l>'
      end

      return vim.fn['coc#refresh']()
    end, expr_opts)

    vim.keymap.set('n', '<leader>lb', function()
      _G.coc_backend_enabled = not _G.coc_backend_enabled
      vim.cmd(_G.coc_backend_enabled and 'CocEnable' or 'CocDisable')
      print('CoC backend ' .. (_G.coc_backend_enabled and 'enabled' or 'disabled'))
    end, { desc = 'Toggle CoC backend' })

    vim.keymap.set('n', '<leader>lc', '<cmd>CocList references<CR>', map_opts)
    vim.keymap.set('n', '<leader>lv', '<cmd>CocList -I symbols<CR>', map_opts)
    vim.keymap.set('n', '<C-b>', '<Plug>(coc-definition)', plug_map_opts)
    vim.keymap.set('n', '<leader>ld', '<Plug>(coc-definition)', plug_map_opts)
    vim.keymap.set('n', '<leader>li', '<Plug>(coc-implementation)', plug_map_opts)
    vim.keymap.set('n', '<leader>ly', '<Plug>(coc-type-definition)', plug_map_opts)
    vim.keymap.set('n', '<leader>lS', '<cmd>CocList outline<CR>', map_opts)
    vim.keymap.set('n', '<leader>lw', '<cmd>CocList -I symbols<CR>', map_opts)
    vim.keymap.set('n', '<leader>lh', '<cmd>lua _G.coc_show_docs()<CR>', map_opts)
    vim.keymap.set('n', '<leader>ls', '<cmd>call CocActionAsync("showSignatureHelp")<CR>', map_opts)
    vim.keymap.set('n', '<leader>lr', '<Plug>(coc-rename)', plug_map_opts)
    vim.keymap.set('n', '<leader>ll', '<Plug>(coc-codelens-action)', plug_map_opts)
    vim.keymap.set('n', '<leader>lt', '<cmd>CocDiagnostics<CR>', map_opts)
    vim.keymap.set('n', '<leader>lT', '<cmd>CocDiagnostics<CR>', map_opts)
    vim.keymap.set('n', '[g', '<Plug>(coc-diagnostic-prev)', plug_map_opts)
    vim.keymap.set('n', ']g', '<Plug>(coc-diagnostic-next)', plug_map_opts)
    vim.keymap.set('n', '<leader>la', '<Plug>(coc-codeaction-cursor)', plug_map_opts)
    vim.keymap.set('v', '<leader>la', '<Plug>(coc-codeaction-selected)', plug_map_opts)

    vim.api.nvim_create_augroup('CocGroup', {})
    vim.api.nvim_create_autocmd('CursorHold', {
      group = 'CocGroup',
      command = "silent call CocActionAsync('highlight')",
      desc = 'Highlight symbol under cursor on CursorHold',
    })
  '';
in
{
  inherit lua name;

  vimPackages = with pkgs.vimPlugins; [
    coc-nvim
  ];

  packages = with pkgs; [
    nodejs_22
  ];
}
