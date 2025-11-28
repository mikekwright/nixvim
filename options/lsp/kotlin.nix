{pkgs, ...}: let
  name = "lsp.kotlin";

  lua =
    /*
    lua
    */
    ''
    -- Configure Kotlin Language Server using vim.lsp.config (Neovim 0.11+)
    vim.lsp.config('kotlin_language_server', {
      cmd = { "${pkgs.kotlin-language-server}/bin/kotlin-language-server" },
      filetypes = { "kotlin", "kt", "kts" },
    })

    -- Enable Kotlin Language Server
    vim.lsp.enable('kotlin_language_server')
  '';
in {
  inherit lua name;

  packages = with pkgs; [
    kotlin-language-server

    zulu
    kotlin
    #  This doesn't exist for the arm linux
    # kotlin-native

    ktlint
    ktfmt

    gradle
    maven
  ];
}
