{pkgs, ...}: let
  name = "lsp.kotlin";

  lua =
    /*
    lua
    */
    ''
    vim.lsp.config('kotlin_language_server', {
      cmd = { "${pkgs.kotlin-language-server}/bin/kotlin-language-server" },
      filetypes = { "kotlin", "kt", "kts" },
    })
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
