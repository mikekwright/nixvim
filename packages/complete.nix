{ lib, ... }:

lib.makeIncludes {
  complete = [
    "lsp.coc"
    "lsp.coc.elixir"
    "lsp.coc.erlang"
    "lsp.coc.golang"
    "lsp.coc.haskell"
    "lsp.coc.kotlin"
    "lsp.coc.markdown"
    "lsp.coc.nix"
    "lsp.coc.python"
    "lsp.coc.rust"
    "lsp.coc.typescript"
    "lsp.coc.zig"

    "lsp.markdown"
    "lsp.formatting"
    "lsp.dap"
    "lsp.neotest"

    "tools"
    "tools.agent-notifications"
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
    "ai.agent"
    "ai.copilot-coc"
    "ai.opencode"
  ];
}
