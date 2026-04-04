{ pkgs, ... }:

let
  name = "lsp.coc.typescript";

  lua = /* lua */ ''
    for _, extension in ipairs({
      'coc-json',
      'coc-yaml',
      'coc-tsserver',
      'coc-eslint',
      'coc-html',
      'coc-css',
    }) do
      _G.ensure_coc_extension(extension)
    end
  '';
in
{
  inherit lua name;

  packages = with pkgs; [
    eslint_d
    typescript
  ];
}
