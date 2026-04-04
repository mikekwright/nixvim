{ pkgs, ... }:

let
  name = "lsp.coc.kotlin";

  lua = /* lua */ ''
    _G.coc_merge_config({
      languageserver = {
        kotlin_language_server = {
          command = '${pkgs.kotlin-language-server}/bin/kotlin-language-server',
          filetypes = { 'kotlin', 'kt', 'kts' },
          rootPatterns = {
            'settings.gradle',
            'settings.gradle.kts',
            'build.gradle',
            'build.gradle.kts',
            'pom.xml',
            '.git',
          },
        },
      },
    })
  '';
in
{
  inherit lua name;

  packages = with pkgs; [
    kotlin-language-server
    zulu
    kotlin
    ktlint
    ktfmt
    gradle
    maven
  ];
}
