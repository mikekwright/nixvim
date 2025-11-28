{ lib, ... }:

lib.makeIncludes
{
  complete = [
    "lsp"
    "lsp.markdown"
    "lsp.formatting"
    "lsp.python"

    "tools"
    "tools.bookmarks"
    "tools.bqf"
    "tools.coverage"
    "tools.db"
    "tools.debugging"
    "tools.mini"
    "tools.noice"
    "tools.snacks"
    "tools.testing"

    "ai"
    "ai.claude"
    "ai.copilot"
  ];
}
