{ lib, ... }:

lib.makeIncludes
{
  complete = [
    "lsp"
    "lsp.markdown"
    "lsp.formatting"
    "lsp.copilot"
    "lsp.dap"
    "lsp.golang"
    "lsp.haskell"
    "lsp.kotlin"
    "lsp.markdown"
    "lsp.neotest"
    "lsp.nix"
    "lsp.python"
    "lsp.rust"
    "lsp.typescript"
    "lsp.zig"

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
  ];
}
