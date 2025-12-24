{ pkgs, ... }:

let
  name = "ai.opencode";

  lua = /*lua*/ ''
    -- OpenCode.nvim configuration
    require('opencode')
  '';
in
{
  inherit name lua;
  
  vimPackages = with pkgs.vimPlugins; [
    opencode-nvim  # Uncomment when available
    
    # Dependencies that might be needed
    plenary-nvim  # Common Neovim library for many plugins
    snacks-nvim
    # nui-nvim      # UI components library (uncomment if needed)
  ];
  
  # Dependencies that OpenCode might need
  packages = with pkgs; [
    curl       # For API requests
    jq         # For JSON processing
  ];
}
