{ ... }:

{
  imports = [
    ./rust-lang.nix
    ./python-lang.nix
    ./otter.nix
  ];

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
