{ lib, ... }:

lib.makeIncludes {
  complete = [
    "lsp.coc"
    "lsp.coc.python"
    "lsp.markdown"
    "lsp.formatting"

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
    "ai.copilot-coc"
  ];
}
