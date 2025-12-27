{ pkgs, ... }:

let
  name = "ai.opencode";

  lua = /*lua*/ ''
    -- OpenCode.nvim configuration
    vim.g.opencode_setup = {
      ask = require("opencode.ui.ask").ask,
      select = require("opencode.ui.select").select,

      prompt = require("opencode.api.prompt").prompt,
      operator = require("opencode.api.operator").operator,
      command = require("opencode.api.command").command,

      toggle = require("opencode.provider").toggle,
      start = require("opencode.provider").start,
      stop = require("opencode.provider").stop,

      statusline = require("opencode.status").statusline,
    }
  '';
in
{
  inherit name lua;
  

  
  vimPackages = with pkgs.vimPlugins; 
    let
      local-opencode-nvim = pkgs.vimUtils.buildVimPlugin {
        name = "opencode-nvim";
        src = pkgs.fetchFromGitHub {
          owner = "NickvanDyke";
          repo = "opencode.nvim";
          rev = "dfca5bb214d78a600781d50da350238b3e6e2621";
          sha256 = "W7fPGiLpKRe1Nw0MckigUijTNq+L9Z+vxOKcf3oNZf0=";
        };
      };
    in
    [
      local-opencode-nvim
      # opencode-nvim  # Uncomment when available
      
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
