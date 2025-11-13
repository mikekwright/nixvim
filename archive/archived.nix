# This is being kept for record purposes only.
{ pkgs, ... }:

let
  luaConfig = /*lua*/ ''
    -- Set up options {{{
    do
      local nixvim_options = {["breakindent"] = false,["encoding"] = "utf-8",["expandtab"] = true,["fileencoding"] = "utf-8",["filetype"] = "on",["hidden"] = true,["history"] = 1000,["ignorecase"] = true,["number"] = true,["relativenumber"] = false,["shiftwidth"] = 2,["showmode"] = true,["showtabline"] = 2,["smartindent"] = true,["softtabstop"] = 2,["tabstop"] = 2,["termguicolors"] = true,["timeoutlen"] = 1000,["wrap"] = false}

      for k,v in pairs(nixvim_options) do
        vim.opt[k] = v
      end
    end
    -- }}}


    vim.loader.disable()

    vim.cmd([[
      
    ]])
    require('oil').setup({})

    require('Comment').setup({})


    local __telescopeExtensions = {}
    for i, extension in ipairs(__telescopeExtensions) do
      require('telescope').load_extension(extension)
    end

    -- LSP {{{
    do
      

      local __lspServers = {{["name"] = "zls"},{["name"] = "tsserver"},{["name"] = "terraformls"},{["name"] = "tailwindcss"},{["name"] = "sqls"},{["name"] = "solargraph"},{["name"] = "rust_analyzer"},{["name"] = "ruff"},{["name"] = "pylyzer"},{["name"] = "prolog_ls"},{["name"] = "perlpls"},{["extraOptions"] = {["cmd"] = {"/nix/store/vppw4b478xrbxa7hxwb09ck3qs59bn33-omnisharp-roslyn-1.39.11/bin/OmniSharp"}},["name"] = "omnisharp"},{["name"] = "nixd"},{["name"] = "nil_ls"},{["name"] = "metals"},{["name"] = "lua_ls"},{["name"] = "lexical"},{["name"] = "kotlin_language_server"},{["extraOptions"] = {["cmd"] = {"/nix/store/qcic3nndsfw1ym2d0p4xwscxb4c5rbxy-vscode-langservers-extracted-4.10.0/bin/vscode-json-language-server","--stdio"}},["name"] = "jsonls"},{["extraOptions"] = {["cmd"] = {"/nix/store/5g2lwsg7v2b2mysckmqpl4kly3b1j3k2-java-language-server-0.2.46/bin/java-language-server"}},["name"] = "java_language_server"},{["extraOptions"] = {["cmd"] = {"/nix/store/qcic3nndsfw1ym2d0p4xwscxb4c5rbxy-vscode-langservers-extracted-4.10.0/bin/vscode-html-language-server","--stdio"}},["name"] = "html"},{["name"] = "helm_ls"},{["name"] = "golangci_lint_ls"},{["name"] = "gopls"},{["extraOptions"] = {["cmd"] = {"/nix/store/aqag1wa5d2aibfh3j9r5856mksr7bcim-fortls-3.1.1/bin/fortls","--hover_signature","--hover_language=fortran","--use_signature_help"}},["name"] = "fortls"},{["extraOptions"] = {["cmd"] = {"/nix/store/36z60b0r0lsjsq9gqr7mlsyzrvj6wndw-elixir-ls-0.21.3/bin/elixir-ls"}},["name"] = "elixirls"},{["name"] = "elmls"},{["extraOptions"] = {["cmd"] = {"/nix/store/qcic3nndsfw1ym2d0p4xwscxb4c5rbxy-vscode-langservers-extracted-4.10.0/bin/vscode-css-language-server","--stdio"}},["name"] = "cssls"}}
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

    require('bufferline').setup{["options"] = {["hover"] = {["enabled"] = false}}}

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
    local __nixvim_autocommands = {
      {
        ["callback"] = open_nvim_tree,
        ["event"] = "VimEnter"
      },{
        ["command"] = "if winnr('$') == 1 && bufname() == 'NvimTree_' . tabpagenr() | quit | endif",
        ["event"] = "BufEnter",
        ["nested"] = true},
        {["callback"] = function()
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

