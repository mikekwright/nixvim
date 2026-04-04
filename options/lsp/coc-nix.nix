{ pkgs, ... }:

let
  name = "lsp.coc.nix";

  lua = /* lua */ ''
    _G.coc_merge_config({
      languageserver = {
        nixd = {
          command = '${pkgs.nixd}/bin/nixd',
          filetypes = { 'nix' },
          rootPatterns = { 'flake.nix', 'shell.nix', 'default.nix', '.git' },
          settings = {
            nixd = {},
          },
        },
      },
    })
  '';
in
{
  inherit lua name;

  vimPackages = with pkgs.vimPlugins; [
    vim-nix
  ];

  packages = with pkgs; [
    nixd
    statix
  ];
}
