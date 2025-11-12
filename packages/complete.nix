{ lib, ... }:

lib.makeIncludes
{
  complete = [
    "lsp"
    "lsp.markdown"
    "lsp.formatting"
  ];
}
