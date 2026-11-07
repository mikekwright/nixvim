{ pkgs, ... }:

let
  nixvimCursor = "${pkgs.cursor-cli}/bin/cursor-agent";

  cursor-wrapper = pkgs.writeShellScriptBin "cursor-nixvim" ''
    exec ${nixvimCursor} "$@"
  '';
in
  cursor-wrapper
