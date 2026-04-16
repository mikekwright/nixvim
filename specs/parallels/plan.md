# Parallels integration plan

## Objective

Prepare a minimal-diff Parallels integration path that fits nixvim's current modular design and stays inert on Linux hosts.

## Scope assumptions from upstream review

The upstream VS Code extension supports:

- local VM lifecycle
- snapshots
- VM creation
- group management
- Docker-in-guest management
- Vagrant/Packer workflows
- Parallels DevOps Service
- VS Code chat integration

This plan intentionally does not start with the full upstream surface.

Initial nixvim implementation should focus on local `prlctl`-based workflows first.

## Implementation approach

- keep the feature under `options/tools/`
- make package inclusion the top-level toggle
- keep Lua embedded in Nix modules
- gate at both Nix evaluation/build time and Lua runtime
- reuse existing picker/UI dependencies before adding new ones

## Work breakdown

### Step 1: add module skeleton

Files:

- `options/tools/parallels/default.nix`
- `options/tools/parallels/runtime.nix`
- `options/tools/parallels/commands.nix`
- `options/tools/parallels/picker.nix`

Tasks:

- create `name = "tools.parallels"`
- compute `isMac = pkgs.stdenv.isDarwin`
- make non-macOS output empty for imports/lua/packages/vimPackages
- add module import to `options/tools/default.nix`
- do not auto-enable the module for Linux-oriented package variants

Acceptance:

- Linux builds remain free of Parallels setup
- module shape matches existing `options/tools/*` patterns

### Step 2: establish runtime state and hard gating

Tasks:

- create `_G.nixvim_parallels`
- add top-level `vim.fn.has('mac')` early return
- add helper to detect required CLI availability
- normalize CLI output into a VM list/state table
- return a safe `not supported on this host` message when running on Linux

Acceptance:

- no commands/autocmds/keymaps created on Linux
- macOS with missing CLI fails safely with notifications, not errors

### Step 3: expose user-facing commands

Tasks:

- add `:ParallelsStatus`
- add `:ParallelsList`
- add start/stop/resume/suspend commands if supported by the analyzed extension/CLI
- add `:ParallelsShell` only if implemented as a safe wrapper around supported local workflows
- add `<leader>P` which-key group

Acceptance:

- commands are discoverable and idempotent
- command failures report useful messages

### Step 4: add picker-based UI

Tasks:

- implement VM selection through existing picker stack
- route picker selection to actions
- store last selected VM in runtime state

Acceptance:

- no new UI plugin required for phase 1/2
- VM actions are reachable without typing full command names

### Step 5: package wiring

Tasks:

- add `"tools.parallels"` to selected package variants, likely `packages/complete.nix` first
- avoid adding to all variants by default

Acceptance:

- feature exposure is explicit per package
- no flake output redesign required

### Step 6: optional project integration

Tasks:

- add `project.nix` only if project/workspace behavior from the VS Code extension is worth preserving
- prefer `.nvim/parallels.lua` or similar project-local config shape
- reuse helper patterns from `project-extensions.nix`

### Step 7: explicitly deferred scopes

Do not start these in the first implementation pass:

- Vagrant box management
- Packer build orchestration
- remote catalog provider management
- remote host/orchestrator management
- DevOps user/role/claim administration
- chat/AI command routing
- editor-owned VM grouping state

Acceptance:

- project behavior stays opt-in
- no mutable global state required across sessions

## Suggested Nix config shape

Keep the initial config local to the module:

```nix
let
  isMac = pkgs.stdenv.isDarwin;
  parallelsConfig = {
    enabled = true;
    command = "prlctl";
    defaultAction = "open-shell";
    picker.backend = "snacks";
    project.enabled = false;
  };
in
...
```

This avoids introducing a new generic option mechanism.

## Risks and mitigations

### Risk: Linux initialization leaks through

Mitigation:

- empty Nix outputs when `!isMac`
- Lua early return before global setup/commands/autocmds
- package wiring kept opt-in instead of always-on

### Risk: extension analysis depends on VS Code-only concepts

Mitigation:

- translate behaviors into commands, pickers, scratch buffers, and notifications
- do not attempt a 1:1 UI clone

### Risk: extra dependencies bloat package variants

Mitigation:

- prefer existing tools/plugins
- add package includes only to variants that need the feature

## Verification

Primary checks:

- `nix build .`
- `nix run .`
- `nix run .#ai`
- `NVIM_DEBUG=1 nix run .`

Manual checks on macOS:

- confirm Parallels commands exist only when `tools.parallels` is included
- confirm picker and command flows work when CLI is present
- confirm missing CLI reports a safe error

Manual checks on Linux:

- confirm build succeeds without Parallels dependencies
- confirm generated Lua contains no active Parallels setup when the feature is excluded or gated
- confirm no `:Parallels...` commands exist

## Minimal-diff recommendations

1. ship phase 1 with read-only status/list UI first
2. add machine actions second
3. postpone project-aware workflows until real usage demands them
4. avoid touching `common/`, `lib/options.nix`, or `flake.nix` beyond necessary include wiring
