{ pkgs, extra-pkgs, ... }:

let
  nixvimClaude = "${extra-pkgs.claude-code.claude-code}/bin/claude";

  claude-wrapper = pkgs.writeShellScriptBin "claude-nixvim" ''
    exec ${nixvimClaude} "$@"
  '';
in
  claude-wrapper
