{ pkgs, ... }:

let
  lspConfigLua = /*lua*/ ''
    -- For help check out (:h lspconfig-setup)
    local lspconfig = require('lspconfig')
  '';
in
{
  imports = [
    ./rust.nix
  ];

  vimPackages = with pkgs.vimPlugins; [
    nvim-lspconfig
  ];

  lua = lspConfigLua;
}
