{ pkgs, extra-pkgs, ... }:

let
  claudeConfig = {
    # Claude Code configuration
    # This can be expanded with Claude-specific keybinds and settings
    # For now, we keep it minimal to match the opencode pattern
    "$schema" = "https://claude.ai/config.json";
  };

  configFile = pkgs.writeText "claude-nvim-config.json" (builtins.toJSON claudeConfig);

  nixvimClaude = "${extra-pkgs.claude-code.claude-code}/bin/claude";

  claude-wrapper = pkgs.writeShellScriptBin "claude-nixvim" ''
    export FORCE_NIXVIM_CLAUDE=''${FORCE_NIXVIM_CLAUDE:-0}

    # Check for system-installed claude (excluding this wrapper)
    system_claude=$(command -v claude 2>/dev/null || true)
    if [[ "''${FORCE_NIXVIM_CLAUDE}" == "0" && -n "$system_claude" && "$system_claude" != "${placeholder "out"}/bin/claude" ]]; then
      exec "$system_claude" "$@"
    else
      exec ${nixvimClaude} "$@"
    fi
  '';
in
  claude-wrapper
