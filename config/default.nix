{ pkgs, ... }:

let
  luaConfig = /*lua*/ ''
    -- Set up globals {{{
    do
      local nixvim_globals = {["mapleader"] = ","}

      for k,v in pairs(nixvim_globals) do
        vim.g[k] = v
      end
    end
    -- }}}


    -- Set up options {{{
    do
      local nixvim_options = {["breakindent"] = false,["encoding"] = "utf-8",["expandtab"] = true,["fileencoding"] = "utf-8",["filetype"] = "on",["hidden"] = true,["history"] = 1000,["ignorecase"] = true,["number"] = true,["relativenumber"] = false,["shiftwidth"] = 2,["showmode"] = true,["showtabline"] = 2,["smartindent"] = true,["softtabstop"] = 2,["tabstop"] = 2,["termguicolors"] = true,["timeoutlen"] = 1000,["wrap"] = false}

      for k,v in pairs(nixvim_options) do
        vim.opt[k] = v
      end
    end
    -- }}}


    vim.loader.disable()

    -- Ignore the user lua configuration
    vim.opt.runtimepath:remove(vim.fn.stdpath('config'))              -- ~/.config/nvim
    vim.opt.runtimepath:remove(vim.fn.stdpath('config') .. "/after")  -- ~/.config/nvim/after
    vim.opt.runtimepath:remove(vim.fn.stdpath('data') .. "/site")     -- ~/.local/share/nvim/site

    vim.cmd([[
      
    ]])
    require('oil').setup({})

    require('Comment').setup({})


    require('telescope').setup({["file_ignore_patterns"] = {"^.git/","^.mypy_cache/","^__pycache__/","^output/","^data/","%.ipynb"},["layout_config"] = {["prompt_position"] = "top"},["selection_caret"] = "> ",["set_env"] = {["COLORTERM"] = "truecolor"},["sorting_strategy"] = "ascending"})

    local __telescopeExtensions = {}
    for i, extension in ipairs(__telescopeExtensions) do
      require('telescope').load_extension(extension)
    end

    require("lualine").setup({["options"] = {["icons_enabled"] = true}})
    require("luasnip").config.set_config({})

    -- LSP {{{
    do
      

      local __lspServers = {{["name"] = "zls"},{["name"] = "tsserver"},{["name"] = "terraformls"},{["name"] = "tailwindcss"},{["name"] = "sqls"},{["name"] = "solargraph"},{["name"] = "rust_analyzer"},{["name"] = "ruff"},{["name"] = "pylyzer"},{["name"] = "prolog_ls"},{["name"] = "perlpls"},{["extraOptions"] = {["cmd"] = {"/nix/store/vppw4b478xrbxa7hxwb09ck3qs59bn33-omnisharp-roslyn-1.39.11/bin/OmniSharp"}},["name"] = "omnisharp"},{["name"] = "nixd"},{["name"] = "nil_ls"},{["name"] = "metals"},{["name"] = "lua_ls"},{["name"] = "lexical"},{["name"] = "kotlin_language_server"},{["extraOptions"] = {["cmd"] = {"/nix/store/qcic3nndsfw1ym2d0p4xwscxb4c5rbxy-vscode-langservers-extracted-4.10.0/bin/vscode-json-language-server","--stdio"}},["name"] = "jsonls"},{["extraOptions"] = {["cmd"] = {"/nix/store/5g2lwsg7v2b2mysckmqpl4kly3b1j3k2-java-language-server-0.2.46/bin/java-language-server"}},["name"] = "java_language_server"},{["extraOptions"] = {["cmd"] = {"/nix/store/qcic3nndsfw1ym2d0p4xwscxb4c5rbxy-vscode-langservers-extracted-4.10.0/bin/vscode-html-language-server","--stdio"}},["name"] = "html"},{["name"] = "helm_ls"},{["name"] = "golangci_lint_ls"},{["name"] = "gopls"},{["extraOptions"] = {["cmd"] = {"/nix/store/aqag1wa5d2aibfh3j9r5856mksr7bcim-fortls-3.1.1/bin/fortls","--hover_signature","--hover_language=fortran","--use_signature_help"}},["name"] = "fortls"},{["extraOptions"] = {["cmd"] = {"/nix/store/36z60b0r0lsjsq9gqr7mlsyzrvj6wndw-elixir-ls-0.21.3/bin/elixir-ls"}},["name"] = "elixirls"},{["name"] = "elmls"},{["extraOptions"] = {["cmd"] = {"/nix/store/qcic3nndsfw1ym2d0p4xwscxb4c5rbxy-vscode-langservers-extracted-4.10.0/bin/vscode-css-language-server","--stdio"}},["name"] = "cssls"}}
      local __lspOnAttach = function(client, bufnr)
        

        
      end
      local __lspCapabilities = function()
        capabilities = vim.lsp.protocol.make_client_capabilities()

        

        return capabilities
      end

      local __setup = {
                on_attach = __lspOnAttach,
                capabilities = __lspCapabilities()
              }

      for i,server in ipairs(__lspServers) do
        if type(server) == "string" then
          require('lspconfig')[server].setup(__setup)
        else
          local options = server.extraOptions

          if options == nil then
            options = __setup
          else
            options = vim.tbl_extend("keep", options, __setup)
          end

          require('lspconfig')[server.name].setup(options)
        end
      end

      require('rust-tools').setup({["server"] = {["on_attach"] = __lspOnAttach}})

    end
    -- }}}

    require('nvim-treesitter.configs').setup({["highlight"] = {["enable"] = true}})

    local function open_nvim_tree(data)

      ------------------------------------------------------------------------------------------

      -- buffer is a directory
      local directory = vim.fn.isdirectory(data.file) == 1

      -- buffer is a [No Name]
      local no_name = data.file == "" and vim.bo[data.buf].buftype == ""

      -- Will automatically open the tree when running setup if startup buffer is a directory,
      -- is empty or is unnamed. nvim-tree window will be focused.
      local open_on_setup = true

      if (directory or no_name) and open_on_setup then
        -- change to the directory
        if directory then
          vim.cmd.cd(data.file)
        end

        -- open the tree
        require("nvim-tree.api").tree.open()
        return
      end

      ------------------------------------------------------------------------------------------

      -- Will automatically open the tree when running setup if startup buffer is a file.
      -- File window will be focused.
      -- File will be found if updateFocusedFile is enabled.
      local open_on_setup_file = false

      -- buffer is a real file on the disk
      local real_file = vim.fn.filereadable(data.file) == 1

      if (real_file or no_name) and open_on_setup_file then

        -- skip ignored filetypes
        local filetype = vim.bo[data.buf].ft
        local ignored_filetypes = {}

        if not vim.tbl_contains(ignored_filetypes, filetype) then
          -- open the tree but don't focus it
          require("nvim-tree.api").tree.toggle({ focus = false })
          return
        end
      end

      ------------------------------------------------------------------------------------------

      -- Will ignore the buffer, when deciding to open the tree on setup.
      local ignore_buffer_on_setup = false
      if ignore_buffer_on_setup then
        require("nvim-tree.api").tree.open()
      end

    end

    require('nvim-tree').setup({["actions"] = {["open_file"] = {["window_picker"] = {["enable"] = false}}},["hijack_directories"] = {["auto_open"] = true},["on_attach"] = function(bufnr)
      nvimTreeOnAttach(bufnr)
    end
    })

    require('bufferline').setup{["options"] = {["hover"] = {["enabled"] = false}}}

    require('CopilotChat').setup({})

    require("otter").activate({ "javascript", "python", "rust", "lua"}, true, true, nil) 

    local function setupRustLang()
      local rt = require('rust-tools')

      rt.setup({
        server = {
          on_attach = function(_, bufnr)
            -- Hover actions
            vim.keymap.set("n", "<C-space>", rt.hover_actions.hover_actions, { buffer = bufnr })
            -- Code action groups
            vim.keymap.set("n", "<Leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
          end,
        },
      })
    end

    setupRustLang()

    -- Lua
    --   (This is the initial config provided by the repo, small adjustments were made)

    local function setupWinshift()
      require("winshift").setup({
        highlight_moving_win = true,  -- Highlight the window being moved
        focused_hl_group = "Visual",  -- The highlight group used for the moving window
        moving_win_options = {
          -- These are local options applied to the moving window while it's
          -- being moved. They are unset when you leave Win-Move mode.
          wrap = false,
          cursorline = false,
          cursorcolumn = false,
          colorcolumn = "",
        },
        keymaps = {
          disable_defaults = false, -- Disable the default keymaps
          win_move_mode = {
            ["h"] = "left",
            ["j"] = "down",
            ["k"] = "up",
            ["l"] = "right",
            ["H"] = "far_left",
            ["J"] = "far_down",
            ["K"] = "far_up",
            ["L"] = "far_right",
            ["<left>"] = "left",
            ["<down>"] = "down",
            ["<up>"] = "up",
            ["<right>"] = "right",
            ["<S-left>"] = "far_left",
            ["<S-down>"] = "far_down",
            ["<S-up>"] = "far_up",
            ["<S-right>"] = "far_right",
          },
        },
        ---A function that should prompt the user to select a window.
        ---
        ---The window picker is used to select a window while swapping windows with
        ---`:WinShift swap`.
        ---@return integer? winid # Either the selected window ID, or `nil` to
        ---   indicate that the user cancelled / gave an invalid selection.
        window_picker = function()
          return require("winshift.lib").pick_window({
            -- A string of chars used as identifiers by the window picker.
            picker_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
            filter_rules = {
              -- This table allows you to indicate to the window picker that a window
              -- should be ignored if its buffer matches any of the following criteria.
              cur_win = true, -- Filter out the current window
              floats = true,  -- Filter out floating windows
              filetype = {},  -- List of ignored file types
              buftype = {},   -- List of ignored buftypes
              bufname = {},   -- List of vim regex patterns matching ignored buffer names
            },
            ---A function used to filter the list of selectable windows.
            ---@param winids integer[] # The list of selectable window IDs.
            ---@return integer[] filtered # The filtered list of window IDs.
            filter_func = nil,
          })
        end,
      })

      -- Start Win-Move mode:
      vim.keymap.set("n", "<C-W>m", "<Cmd>WinShift<CR>", { silent = true, noremap = true })
      vim.keymap.set("n", "<C-W>H", "<Cmd>WinShift left<CR>", { silent = true, noremap = true })
      vim.keymap.set("n", "<C-W>J", "<Cmd>WinShift down<CR>", { silent = true, noremap = true })
      vim.keymap.set("n", "<C-W>K", "<Cmd>WinShift up<CR>", { silent = true, noremap = true })
      vim.keymap.set("n", "<C-W>L", "<Cmd>WinShift right<CR>", { silent = true, noremap = true })
      -- Swap two windows:
      --nnoremap <C-W>X <Cmd>WinShift swap<CR>
    end


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

    local telescopeBuiltin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>ff', telescopeBuiltin.find_files, {})
    vim.keymap.set('n', '<C-p>', telescopeBuiltin.find_files, {})
    vim.keymap.set('n', '<leader>fg', telescopeBuiltin.live_grep, {})
    vim.keymap.set('n', '<leader>fb', telescopeBuiltin.buffers, {})
    vim.keymap.set('n', '<leader>fh', telescopeBuiltin.help_tags, {})

    -- This was pulled from the nvim-tree documentation
    --   https://github.com/nvim-tree/nvim-tree.lua/blob/master/lua/nvim-tree/keymap.lua
    --
    function nvimTreeOnAttach(bufnr)
      local api = require('nvim-tree.api')

      local function opts(desc)
        return {
          desc = 'nvim-tree: ' .. desc,
          buffer = bufnr,
          noremap = true,
          silent = true,
          nowait = true,
        }
      end

      -- BEGIN_DEFAULT_ON_ATTACH
      vim.keymap.set('n', '<C-]>',   api.tree.change_root_to_node,        opts('CD'))
      vim.keymap.set('n', '<C-e>',   api.node.open.replace_tree_buffer,   opts('Open: In Place'))
      vim.keymap.set('n', '<C-k>',   api.node.show_info_popup,            opts('Info'))
      vim.keymap.set('n', '<C-r>',   api.fs.rename_sub,                   opts('Rename: Omit Filename'))
      vim.keymap.set('n', '<C-t>',   api.node.open.tab,                   opts('Open: New Tab'))
      vim.keymap.set('n', '<C-v>',   api.node.open.vertical,              opts('Open: Vertical Split'))
      vim.keymap.set('n', '<C-x>',   api.node.open.horizontal,            opts('Open: Horizontal Split'))
      vim.keymap.set('n', '<BS>',    api.node.navigate.parent_close,      opts('Close Directory'))
      vim.keymap.set('n', '<CR>',    api.node.open.edit,                  opts('Open'))
      vim.keymap.set('n', '<Tab>',   api.node.open.preview,               opts('Open Preview'))
      vim.keymap.set('n', '>',       api.node.navigate.sibling.next,      opts('Next Sibling'))
      vim.keymap.set('n', '<',       api.node.navigate.sibling.prev,      opts('Previous Sibling'))
      vim.keymap.set('n', '.',       api.node.run.cmd,                    opts('Run Command'))
      vim.keymap.set('n', '-',       api.tree.change_root_to_parent,      opts('Up'))
      vim.keymap.set('n', 'a',       api.fs.create,                       opts('Create File Or Directory'))
      vim.keymap.set('n', 'bd',      api.marks.bulk.delete,               opts('Delete Bookmarked'))
      vim.keymap.set('n', 'bt',      api.marks.bulk.trash,                opts('Trash Bookmarked'))
      vim.keymap.set('n', 'bmv',     api.marks.bulk.move,                 opts('Move Bookmarked'))
      vim.keymap.set('n', 'B',       api.tree.toggle_no_buffer_filter,    opts('Toggle Filter: No Buffer'))
      vim.keymap.set('n', 'c',       api.fs.copy.node,                    opts('Copy'))
      vim.keymap.set('n', 'C',       api.tree.toggle_git_clean_filter,    opts('Toggle Filter: Git Clean'))
      vim.keymap.set('n', '[c',      api.node.navigate.git.prev,          opts('Prev Git'))
      vim.keymap.set('n', ']c',      api.node.navigate.git.next,          opts('Next Git'))
      vim.keymap.set('n', 'd',       api.fs.remove,                       opts('Delete'))
      vim.keymap.set('n', 'D',       api.fs.trash,                        opts('Trash'))
      vim.keymap.set('n', 'E',       api.tree.expand_all,                 opts('Expand All'))
      vim.keymap.set('n', 'e',       api.fs.rename_basename,              opts('Rename: Basename'))
      vim.keymap.set('n', ']e',      api.node.navigate.diagnostics.next,  opts('Next Diagnostic'))
      vim.keymap.set('n', '[e',      api.node.navigate.diagnostics.prev,  opts('Prev Diagnostic'))
      vim.keymap.set('n', 'F',       api.live_filter.clear,               opts('Live Filter: Clear'))
      vim.keymap.set('n', 'f',       api.live_filter.start,               opts('Live Filter: Start'))
      vim.keymap.set('n', 'g?',      api.tree.toggle_help,                opts('Help'))
      vim.keymap.set('n', 'gy',      api.fs.copy.absolute_path,           opts('Copy Absolute Path'))
      vim.keymap.set('n', 'ge',      api.fs.copy.basename,                opts('Copy Basename'))
      vim.keymap.set('n', 'H',       api.tree.toggle_hidden_filter,       opts('Toggle Filter: Dotfiles'))
      vim.keymap.set('n', 'I',       api.tree.toggle_gitignore_filter,    opts('Toggle Filter: Git Ignore'))
      vim.keymap.set('n', 'J',       api.node.navigate.sibling.last,      opts('Last Sibling'))
      vim.keymap.set('n', 'K',       api.node.navigate.sibling.first,     opts('First Sibling'))
      vim.keymap.set('n', 'L',       api.node.open.toggle_group_empty,    opts('Toggle Group Empty'))
      vim.keymap.set('n', 'M',       api.tree.toggle_no_bookmark_filter,  opts('Toggle Filter: No Bookmark'))
      vim.keymap.set('n', 'm',       api.marks.toggle,                    opts('Toggle Bookmark'))
      vim.keymap.set('n', 'o',       api.node.open.edit,                  opts('Open'))
      vim.keymap.set('n', 'O',       api.node.open.no_window_picker,      opts('Open: No Window Picker'))
      vim.keymap.set('n', 'p',       api.fs.paste,                        opts('Paste'))
      vim.keymap.set('n', 'P',       api.node.navigate.parent,            opts('Parent Directory'))
      vim.keymap.set('n', 'q',       api.tree.close,                      opts('Close'))
      vim.keymap.set('n', 'r',       api.fs.rename,                       opts('Rename'))
      vim.keymap.set('n', 'R',       api.tree.reload,                     opts('Refresh'))
      --vim.keymap.set('n', 's',       api.node.run.system,                 opts('Run System'))
      vim.keymap.set('n', 'S',       api.tree.search_node,                opts('Search'))
      vim.keymap.set('n', 'u',       api.fs.rename_full,                  opts('Rename: Full Path'))
      vim.keymap.set('n', 'U',       api.tree.toggle_custom_filter,       opts('Toggle Filter: Hidden'))
      vim.keymap.set('n', 'W',       api.tree.collapse_all,               opts('Collapse'))
      vim.keymap.set('n', 'x',       api.fs.cut,                          opts('Cut'))
      vim.keymap.set('n', 'y',       api.fs.copy.filename,                opts('Copy Name'))
      vim.keymap.set('n', 'Y',       api.fs.copy.relative_path,           opts('Copy Relative Path'))
      vim.keymap.set('n', '<2-LeftMouse>',  api.node.open.edit,           opts('Open'))
      vim.keymap.set('n', '<2-RightMouse>', api.tree.change_root_to_node, opts('CD'))

      vim.keymap.set("n", "s", api.node.open.vertical, {})
    end

    require('copilot').setup({
      panel = {
        enabled = true,
        auto_refresh = true,
        keymap = {
          jump_prev = "[[",
          jump_next = "]]",
          accept = "<CR>",
          refresh = "gr",
          open = "<C-P>"
        },
        layout = {
          position = "bottom", -- | top | left | right
          ratio = 0.1
        },
      },

      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = true,
        debounce = 75,
        keymap = {
          accept = "<C-Space>",
          accept_word = false,
          accept_line = false,
          next = "<C-]>",
          prev = "<C-[>",
          dismiss = "<Esc>",
        },
      },

      filetypes = {
        yaml = false,
        markdown = false,
        svn = false,
        cvs = false,
        hgcommit = false
      }
    })

    -- Set up keybinds {{{
    do
      local __nixvim_binds = {{["action"] = "<cmd>Man<CR>",["key"] = "<leader>fm",["mode"] = "n",["options"] = {["noremap"] = true,["silent"] = true}},{["action"] = ":NvimTreeToggle<CR>",["key"] = "<leader>e",["mode"] = "n",["options"] = {["noremap"] = true,["silent"] = true}},{["action"] = ":help lua-guide<CR>",["key"] = "<C-h>",["mode"] = "n",["options"] = {["noremap"] = true,["silent"] = true}}}
      for i, map in ipairs(__nixvim_binds) do
        vim.keymap.set(map.mode, map.key, map.action, map.options)
      end
    end
    -- }}}

    vim.filetype.add({["extension"] = {["v"] = "vlang"}})


    -- This is better as it will only set the keymap if the server supports it
    --  (figure out current capabilities by running:
    --     :lua =vim.lsp.get_active_clients()[1].server_capabilities
    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)

        if client.server_capabilities.hoverProvider then
          vim.keymap.set('n', '<C-k>', vim.lsp.buf.hover, { buffer = args.buf })
        end

        if client.server_capabilities.document_formatting then
          vim.keymap.set('n', '<leader>lf', vim.lsp.buf.formatting, { buffer = args.buf })
        end

        if client.server_capabilities.code_action_provider then
          vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action, { buffer = args.buf })
        end

        if client.server_capabilities.signatureHelpProvider then
          vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, { buffer = args.buf })
        end

        if client.server_capabilities.renameProvider then
          vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, { buffer = args.buf })
        end

        if client.server_capabilities.definitionProvider then
          vim.keymap.set('n', '<C-b>', vim.lsp.buf.definition, { buffer = args.buf })
        end
      end,
    })

    --vim.api.nvim_create_autocmd('LspAttach', {
    --  callback = function(args)
    --    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = args.buf })
    --  end,
    --})

    vim.cmd [[colorscheme jellybeans]]

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

    -- Tab is not supported in neovim by default, this maps to insert mode flow
    --vim.keymap.set("n", "<TAB>", ">>")
    --vim.keymap.set("n", "<S-TAB>", "<<")

    -- Option that lets copy and paste work with system without special clipboard named "+
    vim.api.nvim_set_option("clipboard", "unnamedplus")


    -- Set up autogroups {{
    do
      local __nixvim_autogroups = {["nixvim_binds_LspAttach"] = {["clear"] = true}}

      for group_name, options in pairs(__nixvim_autogroups) do
        vim.api.nvim_create_augroup(group_name, options)
      end
    end
    -- }}
    -- Set up autocommands {{
    do
      local __nixvim_autocommands = {{["callback"] = open_nvim_tree,["event"] = "VimEnter"},{["command"] = "if winnr('$') == 1 && bufname() == 'NvimTree_' . tabpagenr() | quit | endif",["event"] = "BufEnter",["nested"] = true},{["callback"] = function()
      do
        local __nixvim_binds = {}
        for i, map in ipairs(__nixvim_binds) do
          vim.keymap.set(map.mode, map.key, map.action, map.options)
        end
      end
    end
    ,["desc"] = "Load keymaps for LspAttach",["event"] = "LspAttach",["group"] = "nixvim_binds_LspAttach"}}

      for _, autocmd in ipairs(__nixvim_autocommands) do
        vim.api.nvim_create_autocmd(
          autocmd.event,
          {
            group     = autocmd.group,
            pattern   = autocmd.pattern,
            buffer    = autocmd.buffer,
            desc      = autocmd.desc,
            callback  = autocmd.callback,
            command   = autocmd.command,
            once      = autocmd.once,
            nested    = autocmd.nested
          }
        )
      end
    end
    -- }}
  '';
in
{
  imports = [
    ./theme
    ./tools
  ];

  #lua = luaConfig;
}

