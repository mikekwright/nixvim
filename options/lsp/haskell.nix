{pkgs, ...}: let
  name = "lsp.haskell";

  lua =
    /*
    lua
    */
    ''
      -- Configure Haskell Language Server using vim.lsp.config (Neovim 0.11+)
      vim.lsp.config('hls', {
        cmd = { '${pkgs.haskell-language-server}/bin/haskell-language-server-wrapper', '--lsp' },
        filetypes = { 'haskell', 'lhaskell', 'cabal', 'hs' },
      })

      -- Enable Haskell Language Server
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
