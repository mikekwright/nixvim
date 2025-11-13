{pkgs, ...}: let
  name = "lsp.kotlin";

  lua =
    /*
    lua
    */
    ''
    lspconfig.kotlin_language_server.setup({
      filetypes = { "kotlin" , "kt", "kts"},
      capabilities = lsp_cmp_capabilities,
      -- If you don't update you $PATH
      extraOptions = {
        cmd = { "${pkgs.kotlin-language-server}/bin/kotlin-language-server" },
      },
    })
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
