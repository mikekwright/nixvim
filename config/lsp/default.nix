{
  pkgs,
  ...
}: let
  lsp-config-lua =
    /*
    lua
    */
    ''
        -- For help check out (:h lspconfig-setup)
        local lspconfig = require('lspconfig')

        require('cmp').setup({
          sources = {
            { name = 'nvim_lsp' }
          }
        })

        -- The nvim-cmp almost supports LSP's capabilities so You should advertise it to LSP servers..
        local lsp_cmp_capabilities = require('cmp_nvim_lsp').default_capabilities()

      --local __lspServers = {
      --  {
      --    ["name"] = "zls"},
      --    {["name"] = "tsserver"},
      --    {["name"] = "terraformls"},
      --    {["name"] = "tailwindcss"},
      --    {["name"] = "sqls"},
      --    {["name"] = "solargraph"},
      --    {["name"] = "rust_analyzer"},
      --    {["name"] = "ruff"},
      --    {["name"] = "pylyzer"},
      --    {["name"] = "prolog_ls"},
      --    {["name"] = "perlpls"},
      --    {["extraOptions"] = {["cmd"] = {"/nix/store/vppw4b478xrbxa7hxwb09ck3qs59bn33-omnisharp-roslyn-1.39.11/bin/OmniSharp"}},["name"] = "omnisharp"},
      --    {["name"] = "nixd"},
      --    {["name"] = "nil_ls"},
      --    {["name"] = "metals"},
      --    {["name"] = "lua_ls"},
      --    {["name"] = "lexical"},
      --    {["name"] = "kotlin_language_server"},
      --    {["extraOptions"] = {["cmd"] = {"/nix/store/qcic3nndsfw1ym2d0p4xwscxb4c5rbxy-vscode-langservers-extracted-4.10.0/bin/vscode-json-language-server","--stdio"}},["name"] = "jsonls"},
      --    {["extraOptions"] = {["cmd"] = {"/nix/store/5g2lwsg7v2b2mysckmqpl4kly3b1j3k2-java-language-server-0.2.46/bin/java-language-server"}}, ["name"] = "java_language_server"},
      --    {["extraOptions"] = {["cmd"] = {"/nix/store/qcic3nndsfw1ym2d0p4xwscxb4c5rbxy-vscode-langservers-extracted-4.10.0/bin/vscode-html-language-server","--stdio"}},["name"] = "html"},
      --    {["name"] = "helm_ls"},
      --    {["name"] = "golangci_lint_ls"},
      --    {["name"] = "gopls"},
      --    {["extraOptions"] = {["cmd"] = {"/nix/store/aqag1wa5d2aibfh3j9r5856mksr7bcim-fortls-3.1.1/bin/fortls","--hover_signature","--hover_language=fortran","--use_signature_help"}},["name"] = "fortls"},
      --    {["extraOptions"] = {["cmd"] = {"/nix/store/36z60b0r0lsjsq9gqr7mlsyzrvj6wndw-elixir-ls-0.21.3/bin/elixir-ls"}},["name"] = "elixirls"},
      --    {["name"] = "elmls"},{["extraOptions"] = {["cmd"] = {"/nix/store/qcic3nndsfw1ym2d0p4xwscxb4c5rbxy-vscode-langservers-extracted-4.10.0/bin/vscode-css-language-server","--stdio"}},["name"] = "cssls"}}
      --    local __lspOnAttach = function(client, bufnr)

        local lsp_debug_enabled = false

        --  This is better as it will only set the keymap if the server supports it
        --     (figure out current capabilities by running:
        --     :lua =vim.lsp.get_active_clients()[1].server_capabilities
        vim.api.nvim_create_autocmd('LspAttach', {
          callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            dprint('    Checking LSP capabilities for ' .. client.name .. ' (' .. args.data.client_id .. ')')

            local function feature_enable_check(key, name, feature, lsp_option, desc)
              if not feature or not name or not lsp_option then
                dprint("LSP (NS) - " .. name .. ": " .. client.name .. "(" .. args.data.client_id .. ")")
                return
              end

              if type(feature) == "table" then
                print_table(name .. ' feature', feature)
              end

              if type(lsp_option) == 'table' then
                print_table(name .. ' lsp_option', lsp_option)
                return
              end

              dprint("LSP ( S) - " .. name .. ": " .. client.name .. "(" .. args.data.client_id .. ") - " .. key)
              vim.keymap.set('n', key, lsp_option, { buffer = args.buf, desc = desc})
            end

            print_table(client.name .. " server_capabilities", client.server_capabilities)

            --
            -- These are snacks.picker integrations
            --
            snacks = require('snacks')
            feature_enable_check('<leader>lc', 'references', client.server_capabilities.referencesProvider, snacks.picker.lsp_references, "LSP (s): Find references")
            feature_enable_check('<leader>lv', 'symbols', client.server_capabilities.workspaceSymbolProvider, snacks.picker.lsp_symbols, "LSP (s): Show Symbols")

            feature_enable_check('<C-b>', 'definition', client.server_capabilities.definitionProvider, vim.lsp.buf.definition, "LSP: Definitions")
            feature_enable_check('<leader>ld', 'definition', client.server_capabilities.definitionProvider, vim.lsp.buf.definition, "LSP: Definition")
            feature_enable_check('<leader>li', 'implementation', client.server_capabilities.implementationProvider, vim.lsp.buf.implementation, "LSP: Goto implementation")
            feature_enable_check('<leader>lr', 'references', client.server_capabilities.referencesProvider, vim.lsp.buf.references, "LSP: Find references")
            feature_enable_check('<leader>lC', 'references', client.server_capabilities.referencesProvider, vim.lsp.buf.outgoing_calls, "LSP (t): Find outgoing calls")
            feature_enable_check('<leader>lR', 'references', client.server_capabilities.referencesProvider, vim.lsp.buf.incoming_calls, "LSP (t): Find incoming calls")
            --   feature_enable_check('<leader>fw', 'workspace', client.server_capabilities.workspaceSymbolProvider, telescopeBuiltin.lsp_workspace_symbols, "LSP (t): Search workspace Symbols")
            feature_enable_check('<leader>lt', 'type_def', client.server_capabilities.typeDefinitionProvider, vim.lsp.buf.type_definition, "LSP: Type Definition")
            feature_enable_check('<leader>lS', 'symbols', client.server_capabilities.documentSymbolProvider, vim.lsp.buf.document_symbol, "LSP: Document Symbols")
            feature_enable_check('<leader>lw', 'workspace', client.server_capabilities.workspaceSymbolProvider, vim.lsp.buf.workspace_symbol, "LSP: Workspace Symbols")

            feature_enable_check('<leader>lD', 'declaration', client.server_capabilities.declarationProvider, vim.lsp.buf.declaration, "LSP: Goto Declaration")
            feature_enable_check('<leader>lh', 'hover', client.server_capabilities.hoverProvider, vim.lsp.buf.hover, "LSP: Open Hover")
            feature_enable_check('<leader>lH', 'highlight', client.server_capabilities.documentHighlightProvider, vim.lsp.buf.document_highlight, "LSP: Highlight")
            feature_enable_check('<leader>lf', 'format', client.server_capabilities.document_formatting, vim.lsp.buf.formatting, "LSP: Format")
            feature_enable_check('<leader>ls', 'signature', client.server_capabilities.signatureHelpProvider, vim.lsp.buf.signature_help, "LSP: Signature Help")
            feature_enable_check('<leader>la', 'action', client.server_capabilities.code_action_provider, vim.lsp.buf.code_action, "LSP: Code Action")
            feature_enable_check('<leader>lr', 'rename', client.server_capabilities.renameProvider, vim.lsp.buf.rename, "LSP: Rename")

            -- feature_enable_check('<leader>lL', 'document_link', client.server_capabilities.documentLinkProvider, vim.lsp.buf.document_link)
            feature_enable_check('<leader>ll', 'lens', client.server_capabilities.codeLensProvider, vim.lsp.codelens, "LSP: Code Lens")
          end,
        })

        local null_ls = require("null-ls")
        null_ls.setup({
          sources = {
            null_ls.builtins.formatting.stylua,
            null_ls.builtins.completion.spell,

            null_ls.builtins.diagnostics.fish,
            null_ls.builtins.diagnostics.markdownlint,

            -- This is for nix support
            null_ls.builtins.diagnostics.statix,

            -- This is for rust support
            null_ls.builtins.formatting.dxfmt,

            -- Python formatting options
            -- null_ls.builtins.diagnostics.mypy,
            null_ls.builtins.pyright,
            null_ls.builtins.diagnostics.flake8,
            -- null_ls.builtins.formatting.black,
            --  If black is too slow there is a blackd that can be configured (to be faster)
            --      https://github.com/nvimtools/none-ls.nvim/blob/main/doc/BUILTINS.md#blackd

            require("none-ls.diagnostics.eslint"), -- requires none-ls-extras.nvim
          },
        })

        --
        -- Trouble gives an easy view into the list of current issues in the file
        --    https://github.com/folke/trouble.nvim?tab=readme-ov-file
        --
        require('trouble').setup()
        keymapd("<leader>lt", "Trouble: Toggle Diagnostics", ":Trouble diagnostics toggle<CR>")
    '';
in {
  name = "lsp";

  imports = [
    ./neotest.nix
    ./dap.nix
    ./copilot.nix

    ./rust.nix
    ./nix.nix
    ./python.nix
    ./haskell.nix
    ./golang.nix
    ./kotlin.nix
    ./typescript.nix

    ./markdown.nix
    ./formatting.nix
  ];

  lua = lsp-config-lua;

  vimPackages = let
    none-ls-extras = pkgs.vimUtils.buildVimPlugin {
      name = "none-ls-extras.nvim";
      src = pkgs.fetchFromGitHub {
        owner = "nvimtools";
        repo = "none-ls-extras.nvim";
        rev = "387590a3ea0986b33bb1ba90c506e0153dfe14a5";
        sha256 = "9Eatn1LW6k4Bjk50vYd1AfXWSgaJqnTnUNAuLp2ezck=";
      };
    };
    in [
      none-ls-extras
    ]
    ++ (with pkgs.vimPlugins; [
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      trouble-nvim

      none-ls-nvim
    ]);

  packages = with pkgs; [
    markdownlint-cli
    statix

    dioxus-cli # Provides dx for dxfmt
  ];
}
