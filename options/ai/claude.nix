{ pkgs, ... }:

let
  name = "ai.claude";

  lua = /*lua*/ ''
    -- Claude Code configuration
    vim.g.claude_setup = {
      -- Claude-specific configuration can go here
      -- Similar to opencode_setup structure
    }
  '';
in
{
  inherit name lua;
  
  # Claude doesn't currently have a neovim plugin like opencode does,
  # but we keep this structure for consistency and future expansion
  vimPackages = with pkgs.vimPlugins; [
    plenary-nvim  # Common Neovim library for many plugins
    snacks-nvim
  ];
  
  # Dependencies that Claude might need
  packages = with pkgs; [
    curl       # For API requests
    jq         # For JSON processing
  ];
}
