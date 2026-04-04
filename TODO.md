Nixvim Items to change
===============================================

* [x] - Add ability to quickly disable copilot
* [x] Test out [basedpyright](https://docs.basedpyright.com/latest/#/installation?id=command-line) to see if it is better for python
* [ ] Package CoC extensions declaratively instead of relying on `g:coc_global_extensions` installation state
* [x] Split CoC language extension sets by package variant so `coc` and future `python-coc` can stay focused
* [ ] Verify the `copilot-vim` + `@hexuhua/coc-copilot` flow under `nix run .#coc`, including login state, completion priority, manual refresh, and toggle behavior
* [ ] Generate a declarative `coc-settings.json` instead of relying on Coc defaults and Lua globals where possible
* [ ] Review `tools.noice` and diagnostics UX under the `coc` package, since native LSP-specific overrides may no longer all apply
* [ ] Verify the new Coc language-server parity set against real projects for `nix`, `python`, `typescript`, `go`, `rust`, `elixir`, `erlang`, `haskell`, `kotlin`, and `zig`
* [ ] Review whether the now-Coc-backed `complete`, `python`, and `ai` variants should be renamed to reflect that Coc is the default backend
* [x] Decide whether Coc language-server definitions should be split into backend-specific per-language modules instead of living in `options/lsp/coc.nix`


Defects
------------------------------------



New features
-------------------------------------------



Techdebt
---------------------------------------------
