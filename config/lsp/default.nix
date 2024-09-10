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

    --  This is better as it will only set the keymap if the server supports it
    --     (figure out current capabilities by running:
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

    local null_ls = require("null-ls")

    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.completion.spell,

        null_ls.builtins.diagnostics.fish,
        null_ls.builtins.diagnostics.markdownlint,

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
  ];
}
