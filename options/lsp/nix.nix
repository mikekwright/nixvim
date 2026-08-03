{ pkgs, ... }:

let
  name = "lsp.nix";

  lua = /*lua*/ ''
    vim.lsp.config('nixd', {
      cmd = { "${pkgs.nixd}/bin/nixd" },
      settings = {
        nixd = {},
      },
    })
    vim.lsp.enable('nixd')
  '';
in
{
  inherit lua name;

  vimPackages = with pkgs.vimPlugins; [
    vim-nix
  ];

  packages = with pkgs; [
    nixd

    # statix tests are broken in the current nixpkgs pin; skip them
    (statix.overrideAttrs (_: { doCheck = false; }))
  ];
}
