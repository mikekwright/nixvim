{ pkgs, ... }:

let
  name = "lsp.erlang";

  lua = /*lua*/ ''
    vim.lsp.config('elp', {
      cmd = { "${pkgs.erlang-language-platform}/bin/elp", "server" },
    })
    vim.lsp.enable('elp')
  '';
in
{
  inherit lua name;

  packages = with pkgs; [
    erlang-language-platform
    erlang
  ];
}
