# Parallels integration spec

## Goal

Add a future optional Parallels integration to nixvim with a minimal architectural diff and no repo-wide module-system rewrite.

The integration should:

- live under `options/` as an opt-in feature
- keep Lua owned by the surrounding Nix module
- wire any extra packages through the module and package variants
- avoid initializing on non-macOS hosts

## Review summary of `parallels-vscode-extension`

Repository reviewed: `https://github.com/Parallels/parallels-vscode-extension`

Primary implementation shape:

- TypeScript VS Code extension
- main entrypoint: `src/extension.ts`
- startup initialization: `src/initialization.ts`
- main Parallels backend wrapper: `src/services/parallelsDesktopService.ts`
- DevOps backend wrapper: `src/services/devopsService.ts`
- VM creation flows: `src/services/createMachineService.ts`
- tree UI and commands: `src/tree/**`
- built-in catalogs: `data/os.json` and `data/docker.json`

Important architectural conclusion:

- the extension is mostly a UI shell around `prlctl`, helper CLIs, and Parallels DevOps HTTP APIs
- it does not depend on a hidden native SDK that would block a Neovim port
- the hardest part to translate is the VS Code UI, not the Parallels control plane

## What the VS Code extension is capable of

The extension currently exposes a much larger surface area than should be implemented in phase 1 for nixvim.

### 1. VM inventory and lifecycle

- list virtual machines
- show VM state
- show VM IP information when available
- start VM
- start headless VM
- start window VM
- stop VM
- pause VM
- resume VM
- suspend VM
- rename VM
- clone VM
- remove or unregister VM
- enter VM shell

Primary backend mechanism:

- `prlctl list -a -i --json`
- `prlctl start|stop|pause|resume|suspend`
- `prlctl enter`
- `prlctl set`
- `prlctl clone`
- `prlctl delete`
- `prlctl unregister`

### 2. Snapshot management

- list snapshot tree
- create snapshot
- restore snapshot
- delete snapshot
- support flat or nested snapshot display

Primary backend mechanism:

- `prlctl snapshot`
- `prlctl snapshot-list -j`
- `prlctl snapshot-delete`
- `prlctl snapshot-switch`

### 3. VM creation workflows

- create generic VMs
- create ISO-backed VMs
- create macOS VMs from IPSW images
- configure CPU, memory, disk, and devices
- use Packer-driven recipes and catalogs
- support addons/preinstalled content in creation flows

Primary backend mechanism:

- `prlctl create`
- `prlctl set`
- `prl_macvm_create` for older flows
- Packer examples/catalog content

### 4. VM grouping and visibility

- create groups
- rename groups
- run lifecycle operations across a group
- create group snapshots
- hide/show individual VMs or groups

This is mostly extension-owned state and UI behavior, not a Parallels platform primitive.

### 5. Docker container management inside guests

- list containers in a VM
- start, stop, pause, resume, restart, remove containers
- list images and remove images
- create containers from catalog data

Constraint:

- the guest VM must already be running
- this is mainly meaningful for Linux guests

### 6. Vagrant and Packer integration

- detect and manage Vagrant boxes
- initialize Vagrant workflows
- search/download boxes
- clone/update Packer examples
- build automation-oriented VM images

### 7. Parallels DevOps Service integration

- detect/install `prldevops`
- connect to catalog providers and remote host providers
- browse catalog manifests
- pull/push catalog manifests
- manage remote hosts and orchestrators
- manage users, roles, and claims
- stream logs and manage cache

This is a separate higher-complexity integration surface from plain desktop-local `prlctl` usage.

### 8. AI/chat integration

- registers a VS Code chat participant named `parallels`
- supports intent-oriented operations like VM creation and state changes

This is VS Code-specific and should not be treated as required for nixvim.

## Platform constraints observed in the upstream extension

- core Parallels Desktop features are only initialized when the host OS is Darwin
- README explicitly states Apple Mac is required
- some features require Parallels Desktop Pro or Business edition
- some creation flows depend on macOS-only app paths and permissions
- Docker management depends on a running guest and is oriented toward Linux guests

This is directly relevant to nixvim: Linux hosts must not attempt startup or setup for this feature.

## Capability split for nixvim

Not all upstream capability should be ported at once.

### Recommended phase 1 capabilities

- detect host support
- detect `prlctl`
- list VMs
- show status
- start, stop, suspend, resume
- open or enter a VM shell workflow

### Recommended phase 2 capabilities

- snapshots
- clone
- rename
- remember last selected VM
- richer picker and scratch-buffer detail views

### Recommended phase 3 capabilities

- project-aware workflows
- open current project/file in guest-oriented actions
- optional Docker-in-guest helpers

### Explicitly defer from initial nixvim work

- full Vagrant box management
- full Packer authoring/build orchestration
- full DevOps Service provider/user/role/claim management
- VS Code chat-equivalent AI surface
- full group management unless real usage justifies carrying editor-owned state

## Recommended module layout

Use a focused `tools` feature instead of adding anything to `common/`.

```text
options/
  tools/
    parallels/
      default.nix
      runtime.nix
      commands.nix
      picker.nix
      project.nix        # optional, phase 3+
```

Recommended responsibilities:

- `options/tools/parallels/default.nix`
  - module entrypoint
  - sets `name = "tools.parallels"`
  - owns imports and package wiring
  - computes host gating once with `pkgs.stdenv.isDarwin`
- `runtime.nix`
  - creates `_G.nixvim_parallels`
  - stores config/state/helpers
  - adds early Lua return when host is not macOS
- `commands.nix`
  - user commands and keymaps
  - host actions: status, start, stop, open shell, open files
- `picker.nix`
  - Neovim UI surface using existing picker patterns
  - VM list / action list / recent targets
- `project.nix`
  - optional project-aware behavior similar to `project-extensions.nix`
  - only if the VS Code analysis shows real project/workspace semantics worth porting

## Why this layout

- matches the repo split of `common/` always-on vs `options/` conditional
- keeps Parallels self-contained under `tools`
- allows phased delivery without broad rewrites
- follows the existing `options/tools/debugging/` pattern for multi-file feature ownership

## Nix options

This repo does not currently expose a rich per-feature option declaration system. For minimal diff, do not introduce one for this feature.

Instead, use:

1. package inclusion as the primary feature toggle
2. a small module-local config attrset rendered into Lua

Recommended module-level config keys:

```nix
{
  enabled = true;
  command = "prlctl";
  openCommand = "open";
  defaultAction = "open-shell";
  picker = {
    backend = "snacks";
  };
  project = {
    enabled = false;
    markerFiles = [ ".parallels.json" ".nvim/parallels.lua" ];
  };
}
```

Recommended implementation pattern:

- keep this attrset local to `options/tools/parallels/default.nix`
- serialize it into Lua once, similar to other modules that embed runtime config
- avoid adding new generic plumbing to `lib/options.nix` unless multiple future features need the same capability

## Host-platform gating

The feature must not initialize on Linux.

Use two layers of gating:

### Nix-time gating

In `options/tools/parallels/default.nix`:

- compute `isMac = pkgs.stdenv.isDarwin`
- only include Parallels packages/plugins/scripts when `isMac`
- return `""` / `[]` for Lua, imports, packages, and vim packages when not `isMac`

This prevents unnecessary dependencies from entering Linux builds.

### Runtime Lua gating

At the top of the first Parallels Lua block:

```lua
if vim.fn.has('mac') ~= 1 then
  return
end
```

This prevents command registration, autocommands, global state setup, and background checks when Neovim runs on Linux.

Both layers are required:

- Nix gating keeps Linux package graphs clean
- Lua gating prevents accidental setup if a mixed build path ever includes the module

## Lua file structure

Keep all Lua embedded inside Nix modules.

Recommended runtime structure:

```lua
_G.nixvim_parallels = _G.nixvim_parallels or {
  config = {},
  state = {
    initialized = false,
    vms = {},
    last_selection = nil,
  },
  helpers = {},
  actions = {},
  ui = {},
}
```

Suggested Lua responsibilities:

- `helpers`
  - host check
  - CLI availability check
  - command execution wrappers
  - JSON parsing / normalization
- `actions`
  - list VMs
  - start / stop / suspend / resume
  - open shell / launch app / open file in guest
- `ui`
  - picker entries
  - notifications
  - statusline or command output formatting

If reusable filesystem/root helpers are needed, prefer extending `common/helpers.nix` only when the helper is clearly generic.

## Dependency wiring

### Module imports

- add `./parallels` under `options/tools/default.nix` only when the feature is ready
- keep it independent from `tools.debugging` unless the VS Code analysis shows a real DAP relationship

### System packages

Prefer no extra packages if Parallels CLI tools are already expected on macOS hosts.

If a wrapper/helper is needed later, wire it through `packages` in `options/tools/parallels/default.nix`, gated by Darwin.

### Vim plugins

Prefer existing UI dependencies already present in `tools`, especially Snacks-based pickers/notifications.

Do not add a new plugin only for phase 1 if existing picker primitives are sufficient.

### Package variants

Recommended initial package exposure:

- do not add to `common/`
- do not add to every package by default in phase 1
- add `"tools.parallels"` explicitly to package variants that want it, likely `complete` first

This keeps the feature optional and aligned with current package selection.

### Flake outputs

No new flake output type is needed.

Only update existing `packages/*.nix` includes when the feature is ready for a given variant.

## UI mapping: VS Code to Neovim

Based on the analyzed VS Code extension pattern, map UI concepts into native Neovim surfaces instead of recreating VS Code views.

| VS Code concept | Neovim surface |
| --- | --- |
| activity/sidebar view | Snacks picker or command-driven picker |
| command palette actions | `:Parallels...` user commands |
| quick pick VM selector | picker entries with action callbacks |
| status bar connection/state | lualine component or `vim.notify` for phase 1 |
| webview/details panel | floating window or scratch buffer |
| workspace command integration | project-local actions in `project.nix` |

Recommended command set:

- `:ParallelsStatus`
- `:ParallelsList`
- `:ParallelsStart`
- `:ParallelsStop`
- `:ParallelsSuspend`
- `:ParallelsResume`
- `:ParallelsShell`
- `:ParallelsOpenFile`

Recommended keymap group:

- `<leader>P` = Parallels

Example sub-mapping:

- `<leader>Ps` status
- `<leader>Pl` list/select VM
- `<leader>Pp` start/resume current VM
- `<leader>Px` stop/suspend current VM
- `<leader>Pt` open guest shell / terminal workflow

## Phased scope

### Phase 1: host-safe read-only integration

- Darwin gating at Nix and Lua layers
- detect CLI presence
- list VMs
- show VM status
- picker + user commands
- notifications for unavailable host/CLI

### Phase 2: interactive machine actions

- start / stop / suspend / resume
- remember last selected VM
- optional lualine status component

### Phase 3: project-aware workflows

- project-local Parallels config file or `.nvim/parallels.lua`
- open current file or project in target VM
- map workspace concepts from the VS Code extension into project actions

### Phase 4: deeper editor integration

- background refresh where justified
- buffer-local helpers for guest-target workflows
- optional debugging or task bridges only if directly supported by the analyzed extension

## Non-goals for initial architecture

- no repo-wide option-system redesign
- no Linux fallback implementation
- no always-on common module
- no mandatory new flake outputs
- no standalone Lua config tree outside Nix modules

## Verification plan for future implementation

- `nix build .`
- `nix run .`
- `nix run .#ai`
- `NVIM_DEBUG=1 nix run .`

Platform checks:

- on macOS: confirm commands and keymaps register only when the feature is included
- on Linux: confirm Parallels module contributes no packages/plugins/Lua setup and no commands are created
