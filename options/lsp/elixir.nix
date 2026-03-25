{ pkgs, ... }:

let
  name = "lsp.elixir";

  lua = /*lua*/ ''
    vim.lsp.config('elixirls', {
      cmd = { "${pkgs.elixir-ls}/bin/elixir-ls" },
    })
    vim.lsp.enable('elixirls')
  '';
in
{
  inherit lua name;

  packages = with pkgs; [
    elixir-ls
    elixir
  ];
}
