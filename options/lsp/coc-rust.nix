{ pkgs, ... }:

let
  name = "lsp.coc.rust";

  lua = /* lua */ ''
    _G.ensure_coc_extension('coc-rust-analyzer')
  '';
in
{
  inherit lua name;

  packages = with pkgs; [
    rust-analyzer
    rustc
    cargo
  ];
}
