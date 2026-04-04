# Architecture Notes

## LSP and completion backends

- `options/lsp/default.nix` remains the native Neovim LSP + Blink backend.
- `options/lsp/coc.nix` is the alternative `coc.nvim` backend.
- Package variants must choose one backend or the other. They should not include both `lsp` and `lsp.coc`.

## Copilot integration

- `options/ai/copilot.nix` remains the Blink/native-LSP Copilot path.
- `options/ai/copilot-coc.nix` is the CoC-specific Copilot path.
- The first CoC migration keeps extension selection in-module through `g:coc_global_extensions` so the diff stays small.
- Follow-up work should move CoC extensions to a more declarative packaging story if this backend becomes long-term.

## Package strategy

- Existing package variants stay on the native backend.
- New CoC support is exposed as a separate package variant so migration can be tested without regressing the current setup.
