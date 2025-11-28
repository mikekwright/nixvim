{ pkgs, ... }:

let
  name = "lsp.nix";

  lua = /*lua*/ ''
    -- Configure nixd LSP using vim.lsp.config (Neovim 0.11+)
    vim.lsp.config('nixd', {
      cmd = { "${pkgs.nixd}/bin/nixd" },
      -- Server-specific settings. See `:help vim.lsp.config`
      settings = {
        nixd = {},
      },
    })

    -- Enable nixd LSP
    vim.lsp.enable('nixd')
  '';
in
{
  inherit lua name;

  vimPackages = with pkgs.vimPlugins; [
    vim-nix
  ];

  packages = with pkgs; [
    nixd

    statix
  ];
}
