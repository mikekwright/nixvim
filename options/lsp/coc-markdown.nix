{ ... }:

let
  name = "lsp.coc.markdown";

  lua = /* lua */ ''
    _G.ensure_coc_extension('coc-markdownlint')
  '';
in
{
  inherit lua name;
}
