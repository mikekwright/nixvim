{pkgs, ...}: let
  haskell_lua =
    /*
    lua
    */
    ''
      lspconfig.hls.setup({
        filetypes = { 'haskell', 'lhaskell', 'cabal', 'hs' },
        capabilities = lsp_cmp_capabilities,
        extraOptions = {
          cmd = { '${pkgs.haskell-language-server}/bin/haskell-language-server-wrapper', '--lsp' },
        },
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
    cabal-install
    ghc
  ];
}
