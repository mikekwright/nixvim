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

  #
  # Maybe look at this tool in the future
  #   https://github.com/MrcJkb/haskell-tools.nvim
  #
  lua = haskell_lua;

  packages = with pkgs; [
    haskell-language-server
  ];
}