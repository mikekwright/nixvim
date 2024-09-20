{pkgs, ...}: let
  haskell_lua =
    /*
    lua
    */
    ''
      lspconfig.hls.setup({
        filetypes = { 'haskell', 'lhaskell', 'cabal' },
      })
    '';
in {
  lua = haskell_lua;

  packages = with pkgs; [
    haskell-language-server
  ];
}
