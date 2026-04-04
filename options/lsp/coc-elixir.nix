{ pkgs, ... }:

let
  name = "lsp.coc.elixir";

  lua = /* lua */ ''
    _G.coc_merge_config({
      languageserver = {
        elixirls = {
          command = '${pkgs.elixir-ls}/bin/elixir-ls',
          filetypes = { 'elixir', 'eelixir', 'heex' },
          rootPatterns = { 'mix.exs', '.git' },
        },
      },
    })
  '';
in
{
  inherit lua name;

  packages = with pkgs; [
    elixir-ls
    elixir
  ];
}
