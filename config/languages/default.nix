{ ... }:

# Get more help by :help lsp
let
  luaConfig = /*lua*/ ''

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
  '';
in
{
  imports = [
    ./rust-lang.nix
    ./python-lang.nix
    ./otter.nix
  ];

  extraConfigLua = luaConfig;
  #keymaps = [];

  plugins = {
    # Trying to use these as the defaults for nix
    #   https://github.com/nix-community/nixvim/blob/main/plugins/lsp/language-servers/default.nix
    lsp = {
      enable = true;
      servers = {
        # Lua support
        lua-ls.enable = true;

        ## Web ones
        # Typescript support
        tsserver.enable = true;
        # Tailwind CSS support
        tailwindcss.enable = true;
        # HTML support
        html.enable = true;
        # Elm support
        elmls.enable = true;
        # CSS support
        cssls.enable = true;
        # Json support
        jsonls.enable = true;

        # Java support
        java-language-server.enable = true;
        # Scala support
        metals.enable = true;


        # Perl support
        perlpls.enable = true;

        # C# support
        omnisharp.enable = true;


        # Fotran
        fortls.enable = true;
        # Prolog support
        prolog-ls.enable = true;

        # golang support
        gopls.enable = true;
        golangci-lint-ls.enable = true;

        # Kotlin support
        kotlin-language-server.enable = true;

        # Elixir support
        lexical.enable = true;
        elixirls.enable = true;

        # nix
        nil-ls.enable = true;
        nixd.enable = true;

        # Ruby
        solargraph.enable = true;

        # Zig support
        zls.enable = true;

        # SQL support
        sqls.enable = true;

        # Terraform support
        terraformls.enable = true;
        # Helm
        helm-ls.enable = true;
      };
    };

    nix.enable = true;
    zig.enable = true;
  };
}
