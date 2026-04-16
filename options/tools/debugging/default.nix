{ pkgs, ... }:

let
  name = "tools.debugging";

  lua = /* lua */ ''
    _G.nixvim_debugger = _G.nixvim_debugger or {}
    _G.nixvim_debugging = _G.nixvim_debugger
  '';
in
{
  inherit name lua;

  imports = [
    ./common.nix
    ./dap.nix
    ./project-dap.nix
    ./vscode.nix
    ./breakpoints.nix
  ];

  vimPackages = with pkgs.vimPlugins; [
    nvim-dap
    nvim-dap-ui
    nvim-nio
  ];
}
