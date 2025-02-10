{pkgs, ...}: let
  kotlin-lua =
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

  #
  # Maybe look at this tool in the future
  #   https://github.com/MrcJkb/haskell-tools.nvim
  #
  lua = kotlin-lua;

  packages = with pkgs; [
    kotlin-language-server

    zulu
    kotlin
    kotlin-native

    ktlint
    ktfmt

    gradle
    maven
  ];
}
