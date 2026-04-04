{ pkgs, ... }:

let
  name = "lsp.coc.haskell";

  lua = /* lua */ ''
    _G.coc_merge_config({
      languageserver = {
        hls = {
          command = '${pkgs.haskell-language-server}/bin/haskell-language-server-wrapper',
          args = { '--lsp' },
          filetypes = { 'haskell', 'lhaskell', 'cabal', 'hs' },
          rootPatterns = { 'hie.yaml', 'stack.yaml', 'cabal.project', 'package.yaml', '.git' },
        },
      },
    })
  '';
in
{
  inherit lua name;

  packages = with pkgs; [
    haskell-language-server
    cabal-install
    ghc
  ];
}
