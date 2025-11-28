{ pkgs, ... }:

# Does not currently work (2025-11-27)
let
  name = "lsp.dlang";

  # Build vim-dlang-phobos-highlighter plugin from GitHub
  vim-dlang-phobos-highlighter = pkgs.vimUtils.buildVimPlugin {
    name = "vim-dlang-phobos-highlighter";
    src = pkgs.fetchFromGitHub {
      owner = "SirSireesh";
      repo = "vim-dlang-phobos-highlighter";
      rev = "11e24ea28c91fdf44df11ee0c9dbe4c001c5cc8a";
      sha256 = "sha256-qGhvVOzaXaGxHmJkr0xPCLFv8hnWpqPEhP3Gf9tNrdc=";
    };
  };

  lua = /*lua*/ ''
    -- Configure serve-d LSP using vim.lsp.config (Neovim 0.11+)
    vim.lsp.config('serve_d', {
      cmd = { "${pkgs.serve-d}/bin/serve-d" },
      filetypes = { "d", "di" },
      root_markers = { "dub.json", "dub.sdl", ".git" },
      single_file_support = true,
      -- Server-specific settings for serve-d
      settings = {
        d = {
          -- Enable auto-formatting
          enableFormatting = true,
          -- Enable code actions
          enableCodeActions = true,
          -- Enable auto-imports
          enableAutoImports = true,
        },
      },
    })

    -- Enable serve-d LSP
    vim.lsp.enable('serve_d')
  '';
in
{
  inherit lua name;

  vimPackages = [
    vim-dlang-phobos-highlighter
  ];

  packages = with pkgs; [
    # serve-d: D Language Server Protocol implementation
    serve-d

    # DMD: Official reference compiler for the D language
    dmd

    # DUB: Package and build manager for D programs and libraries
    dub

    # LDC: LLVM-based D compiler (alternative to DMD, often faster)
    ldc

    # dtools: Ancillary tools for the D programming language
    # Includes: rdmd (run D programs like scripts), ddemangle, dustmite, etc.
    dtools
  ];
}
