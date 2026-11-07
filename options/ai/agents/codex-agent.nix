{ pkgs, ... }:

let
  nixvimCodex = "${pkgs.codex}/bin/codex";

  codex-wrapper = pkgs.writeShellScriptBin "codex-nixvim" ''
    exec ${nixvimCodex} "$@"
  '';
in
  codex-wrapper
