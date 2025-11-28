{ lib, ... }:

lib.makeIncludes
{
  extensions = [
    "lsp"
    "lsp.markdown"
    "lsp.formatting"
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
  ];

  complete = [
    "ai"
    "ai.claude"
    "ai.copilot"

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
  ];
}
