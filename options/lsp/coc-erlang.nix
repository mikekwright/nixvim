{ pkgs, ... }:

let
  name = "lsp.coc.erlang";

  lua = /* lua */ ''
    _G.coc_merge_config({
      languageserver = {
        elp = {
          command = '${pkgs.erlang-language-platform}/bin/elp',
          args = { 'server' },
          filetypes = { 'erlang' },
          rootPatterns = { 'rebar.config', 'erlang.mk', '.git' },
        },
      },
    })
  '';
in
{
  inherit lua name;

  packages = with pkgs; [
    erlang-language-platform
    erlang
  ];
}
