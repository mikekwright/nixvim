{ pkgs, extra-pkgs, ... }:

let
  name = "ai.binaries";

  opencode-agent = import ./agents/opencode-agent.nix { inherit pkgs extra-pkgs; };
  claude-agent = import ./agents/claude-agent.nix { inherit pkgs extra-pkgs; };

  # Publishes the bundled wrapper paths so ai.agent prefers them over plain
  # PATH lookups; this lua only exists in builds that include ai.binaries
  lua = /*lua*/ ''
    vim.g.ai_agent_commands = {
      opencode = "${opencode-agent}/bin/opencode-nixvim",
      claude = "${claude-agent}/bin/claude-nixvim",
    }
  '';
in
{
  inherit name lua;

  # Bundled claude and opencode binaries, only included in the full mode so
  # the default (complete) build stays lighter and relies on system installs
  packages = [
    claude-agent
    opencode-agent
  ];
}
