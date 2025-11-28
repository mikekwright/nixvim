{pkgs, ...}: let
  name = "lsp.haskell";

  lua =
    /*
    lua
    */
    ''
      vim.lsp.config('hls', {
        cmd = { '${pkgs.haskell-language-server}/bin/haskell-language-server-wrapper', '--lsp' },
        filetypes = { 'haskell', 'lhaskell', 'cabal', 'hs' },
      })
      vim.lsp.enable('hls')
    '';
in {
  inherit lua name;
  #
  # Maybe look at this tool in the future
  #   https://github.com/MrcJkb/haskell-tools.nvim
  #

  packages = with pkgs; [
    haskell-language-server
    cabal-install
    ghc
  ];
}
