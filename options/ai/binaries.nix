{ pkgs, extra-pkgs, ... }:

let
  name = "ai.binaries";

  opencode-agent = import ./agents/opencode-agent.nix { inherit pkgs extra-pkgs; };
  claude-agent = import ./agents/claude-agent.nix { inherit pkgs extra-pkgs; };
in
{
  inherit name;

  # Bundled claude and opencode binaries, only included in the full mode so
  # the default (complete) build stays lighter and relies on system installs
  packages = [
    claude-agent
    opencode-agent
  ];
}
