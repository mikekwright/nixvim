{ pkgs, extra-pkgs, ... }:

let
  lsp-config-lua = /*lua*/ ''
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
        dprint('    Checking LSP capabilities for ' .. client.name .. ' (' .. args.buf .. ')')

        local function feature_enable_check(key, name, feature, lsp_option)
          if feature then
            dprint("LSP ( S) - " .. name .. ": " .. client.name .. "(" .. args.buf .. ") - " .. key)
            vim.keymap.set('n', key, lsp_option, { buffer = args.buf })
          else
            -- dprint("LSP (US) - " .. name .. ": " .. client.name .. "(" .. args.buf .. ")")
          end
        end

        --
        -- Features with telescope integrated capabilities
        --
        local telescopeBuiltin = require('telescope.builtin')
        if telescopeBuiltin then
          feature_enable_check('<C-b>', 'definition', client.server_capabilities.definitionProvider, telescopeBuiltin.lsp_definitions)
          feature_enable_check('<leader>ld', 'definition', client.server_capabilities.definitionProvider, telescopeBuiltin.lsp_definitions)
          feature_enable_check('<leader>li', 'implementation', client.server_capabilities.implementationProvider, telescopeBuiltin.lsp_implementation)
          feature_enable_check('<leader>lc', 'references', client.server_capabilities.referencesProvider, telescopeBuiltin.lsp_references)
          feature_enable_check('<leader>lR', 'references', client.server_capabilities.referencesProvider, telescopeBuiltin.lsp_incoming_calls)
          feature_enable_check('<leader>lC', 'references', client.server_capabilities.referencesProvider, telescopeBuiltin.lsp_outgoing_calls)
          feature_enable_check('<leader>lt', 'type_def', client.server_capabilities.typeDefinitionProvider, telescopeBuiltin.lsp_type_definitions)
          feature_enable_check('<leader>fs', 'symbols', client.server_capabilities.documentSymbolProvider, telescopeBuiltin.lsp_document_symbols)
          feature_enable_check('<leader>lS', 'symbols', client.server_capabilities.documentSymbolProvider, telescopeBuiltin.lsp_document_symbols)
          feature_enable_check('<leader>lw', 'workspace', client.server_capabilities.workspaceSymbolProvider, telescopeBuiltin.lsp_workspace_symbols)
          feature_enable_check('<leader>fw', 'workspace', client.server_capabilities.workspaceSymbolProvider, telescopeBuiltin.lsp_workspace_symbols)

        else
          feature_enable_check('<C-b>', 'definition', client.server_capabilities.definitionProvider, vim.lsp.buf.definition)
          feature_enable_check('<leader>ld', 'definition', client.server_capabilities.definitionProvider, vim.lsp.buf.definition)
          feature_enable_check('<leader>li', 'implementation', client.server_capabilities.implementationProvider, vim.lsp.buf.implementation)
          feature_enable_check('<leader>lr', 'references', client.server_capabilities.referencesProvider, vim.lsp.buf.references)
          -- feature_enable_check('<leader>lr', 'references', client.server_capabilities.referencesProvider, "<CMD>Telescope lsp_references<CR>")
          feature_enable_check('<leader>lt', 'type_def', client.server_capabilities.typeDefinitionProvider, vim.lsp.buf.type_definition)
          feature_enable_check('<leader>lS', 'symbols', client.server_capabilities.documentSymbolProvider, vim.lsp.buf.document_symbol)
          feature_enable_check('<leader>lw', 'workspace', client.server_capabilities.workspaceSymbolProvider, vim.lsp.buf.workspace_symbol)
        end

        --
        -- Features without telescope integrated capabilities
        --
        feature_enable_check('<leader>lD', 'declaration', client.server_capabilities.declarationProvider, vim.lsp.buf.declaration)
        feature_enable_check('<leader>lh', 'hover', client.server_capabilities.hoverProvider, vim.lsp.buf.hover)
        feature_enable_check('<leader>lH', 'highlight', client.server_capabilities.documentHighlightProvider, vim.lsp.buf.document_highlight)
        feature_enable_check('<leader>lf', 'format', client.server_capabilities.document_formatting, vim.lsp.buf.formatting)
        feature_enable_check('<leader>ls', 'signature', client.server_capabilities.signatureHelpProvider, vim.lsp.buf.signature_help)
        feature_enable_check('<leader>la', 'action', client.server_capabilities.code_action_provider, vim.lsp.buf.code_action)
        feature_enable_check('<leader>lr', 'rename', client.server_capabilities.renameProvider, vim.lsp.buf.rename)
        
        --feature_enable_check('<leader>lR', 'references', client.server_capabilities.referencesProvider, vim.lsp.buf.clear_references)

        -- feature_enable_check('<leader>lL', 'document_link', client.server_capabilities.documentLinkProvider, vim.lsp.buf.document_link)
        feature_enable_check('<leader>ll', 'lens', client.server_capabilities.codeLensProvider, vim.lsp.codelens)
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

  '';
in
{
  name = "lsp";

  imports = [
    ./rust.nix
    ./nix.nix
    ./python.nix
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
  ] ++ (with extra-pkgs.nvim-lspconfig-pkgs.vimPlugins; [
    nvim-lspconfig
    nvim-cmp
    cmp-nvim-lsp

    none-ls-nvim
  ]);

  packages = with pkgs; [
    markdownlint-cli
    statix

    #mypy
    #black
    #flake8

    dioxus-cli  # Provides dx for dxfmt
  ];
}
