{ pkgs, ... }:

let
  lsp-config-lua = /*lua*/ ''
    -- For help check out (:h lspconfig-setup)
    local lspconfig = require('lspconfig')


  '';
in
{
  name = "lsp";

  imports = [
    ./rust.nix
  ];

  lua = lsp-config-lua;

  vimPackages =  [
  ] ++ (with pkgs.vimPlugins; [
    nvim-lspconfig
    nvim-cmp
  ]);

}
