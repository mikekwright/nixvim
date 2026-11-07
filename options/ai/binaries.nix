{ pkgs, extra-pkgs, ... }:

let
  name = "ai.binaries";

  claude-agent = import ./agents/claude-agent.nix { inherit pkgs extra-pkgs; };
  cursor-agent = import ./agents/cursor-agent.nix { inherit pkgs; };
  codex-agent = import ./agents/codex-agent.nix { inherit pkgs; };
  opencode-agent = import ./agents/opencode-agent.nix { inherit pkgs extra-pkgs; };
  grok-agent = import ./agents/grok-agent.nix { inherit pkgs; };

  # Publishes the bundled wrapper paths so ai.agent prefers them over plain
  # PATH lookups; this lua only exists in builds that include ai.binaries
  lua = /*lua*/ ''
    vim.g.ai_agent_commands = {
      claude = "${claude-agent}/bin/claude-nixvim",
      cursor = "${cursor-agent}/bin/cursor-nixvim",
      codex = "${codex-agent}/bin/codex-nixvim",
      opencode = "${opencode-agent}/bin/opencode-nixvim",
      grok = "${grok-agent}/bin/grok-nixvim",
    }
  '';
in
{
  inherit name lua;

  # Bundled agent binaries, only included in the full mode so the default
  # (complete) build stays lighter and relies on system installs
  packages = [
    claude-agent
    cursor-agent
    codex-agent
    opencode-agent
    grok-agent
  ];
}
