{ pkgs, ... }:

let
  nixvimGrok = "${pkgs.grok-build}/bin/grok";

  grok-wrapper = pkgs.writeShellScriptBin "grok-nixvim" ''
    exec ${nixvimGrok} "$@"
  '';
in
  grok-wrapper
