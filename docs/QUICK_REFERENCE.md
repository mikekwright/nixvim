# Nixvim Quick Reference Guide

## Project at a Glance

A **reproducible Neovim configuration system** built with Nix Flakes that generates complete, pre-configured Neovim binaries with all plugins and dependencies included.

## Key Directories and Their Purpose

| Directory | Purpose | Contains |
|-----------|---------|----------|
| `flake.nix` | Entry point & outputs | Package definitions, system configs |
| `lib/` | Module infrastructure | Loading, merging, option filtering |
| `common/` | Always-loaded features | Base settings, keymaps, UI, terminal |
| `options/lsp/` | Language servers | One file per language (rust, python, etc) |
| `options/ai/` | AI integration | Copilot, agents, avante, opencode |
| `options/tools/` | Development tools | Snacks, noice, mini, debugging, etc |
| `packages/` | Config variants | complete, minimal, python, ai |

## Module System Overview

```
Nix Module (.nix file)
├── name: "identifier"
├── lua: "Lua code that runs at startup"
├── afterLua: "Lua code that runs after everything"
├── vimPackages: [list of plugins]
├── packages: [list of system packages]
├── imports: [child modules]
└── common: true (if always included)
     │
     ├─ Importer combines all modules
     ├─ Concatenates Lua (in order)
     ├─ Collects all plugins
     ├─ Gathers all packages
     │
     └─> Final Output: init.lua + plugins + packages
```

## Adding Custom Functionality

### Quick Start: Add to Existing Module

Edit a file like `/options/tools/noice.nix`, add Lua to the `lua` field:

```nix
lua = /*lua*/ ''
  -- Your code here
  keymapd("<leader>xx", "Description", function()
    -- Action
  end)
'';
```

### Full Custom Module

Create `/options/tools/my-feature.nix`:

```nix
{ pkgs, ... }:

let
  name = "tools.my-feature";
  
  lua = /*lua*/ ''
    keymapd("<leader>mf", "My Feature", function()
      vim.notify("Working!")
    end)
  '';
in
{
  inherit name lua;
  vimPackages = with pkgs.vimPlugins; [];
  packages = with pkgs; [];
}
```

Then add to package (e.g., `/packages/complete.nix`):

```nix
complete = [
  "tools"
  "tools.my-feature"  # Add this
];
```

## Common Keymaps and Patterns

### Top-Level Leader Groups (from `whichkey.nix`)

```
<leader>a - AI tools
<leader>b - Buffer commands
<leader>d - Debug
<leader>e - Explorer/file tree
<leader>f - Find
<leader>g - Git
<leader>h - Help
<leader>l - LSP
<leader>m - Move/bookmark
<leader>r - Run
<leader>t - Terminal
<leader>w - Windows (C-w proxy)
<leader>? - Show which-key menu
```

### Keymap Helpers (in base.nix, available everywhere)

```lua
keymap("<leader>x", ":Command<CR>")                    -- Basic
keymapd("<leader>x", "Description", ":Command<CR>")   -- With which-key desc
nkeymap("<leader>x", function() end)                  -- Normal mode, noremap
tkeymap("<C-x>", "<action>")                          -- Terminal mode
xkeymapd("<leader>x", "Desc", function() end)        -- Visual mode
vkeymapd("<leader>x", "Desc", function() end)        -- V-mode
ikeymapd("<leader>x", "Desc", function() end)        -- Insert mode
```

## Global Utilities & Functions

### From `base.nix`
- Keymap functions (see above)
- Debug utilities: `dd()`, `bt()` (via snacks)
- Config values: `vim.g.mapleader = ','`

### From `funcs.nix`
- `find_window_for_buffer(buf)` - Find window with buffer

## Notification System (Noice)

### Sending Notifications

```lua
vim.notify("Message", vim.log.levels.INFO)    -- Info
vim.notify("Warning!", vim.log.levels.WARN)   -- Warning
vim.notify("Error!", vim.log.levels.ERROR)    -- Error
```

### Existing Noice Features
- **Bottom display** (top_down = false)
- **Fade animations** (3-second timeout)
- **LSP progress** display in mini window
- **Custom routing** for different message types

### View Noice History
- `<leader>hn` - Show all notification details
- `:Noice` command for history

## Plugin Management

### Adding a Plugin

In your module's `vimPackages`:

```nix
vimPackages = with pkgs.vimPlugins; [
  plugin-name  # Must exist in nixpkgs
];
```

### Building Custom Plugin

If not in nixpkgs:

```nix
let
  my-plugin = pkgs.vimUtils.buildVimPlugin {
    name = "my-plugin";
    src = pkgs.fetchFromGitHub {
      owner = "user";
      repo = "repo";
      rev = "v1.0.0";
      sha256 = "...";
    };
  };
in
{
  vimPackages = [ my-plugin ] ++ ...;
}
```

## Building and Testing

```bash
# Run complete package
nix run .

# Run specific variant
nix run .#minimal
nix run .#python
nix run .#ai

# Debug output (shows generated Lua)
NVIM_DEBUG=1 nix run .

# Build standalone
nix build .
./result/bin/nvim

# From GitHub
nix run github:mikekwright/nixvim
nix run github:mikekwright/nixvim#python
```

## Module Loading Order

1. All `common` modules always load
2. Optionally-included modules load based on `packages/*.nix` definitions
3. Module `imports` are resolved recursively
4. All Lua code concatenated in order (with BEGIN/END markers)
5. `afterLua` code runs after everything
6. Single `init.lua` generated with everything combined

## File Organization Patterns

### Adding to Category

**LSP**: Create in `/options/lsp/language.nix`
**AI**: Create in `/options/ai/feature.nix`
**Tools**: Create in `/options/tools/feature.nix`

All get automatically discoverable if:
1. Module is defined correctly
2. Package definition includes it
3. Keymaps use `keymapd()` with descriptions

### No Runtime Config Needed

- Everything is Nix-declarative
- No `.config/nvim/` files needed
- No `init.lua` files (generated automatically)
- All plugins pre-built into the binary

## Key Configuration Files

```
flake.nix                    <- Inputs, systems, package variants
lib/importer.nix             <- Module merging, Lua concatenation
lib/options.nix              <- Feature flags
common/base.nix              <- Global functions, keymaps, settings
common/whichkey.nix          <- Keymap group definitions
options/tools/noice.nix      <- Notifications
options/tools/snacks.nix     <- Snacks hub (picker, zen, etc)
packages/complete.nix        <- "Complete" variant definition
packages/minimal.nix         <- "Minimal" variant definition
```

## Typical Development Workflow

1. **Identify where change goes**
   - Bug fix or enhancement: Edit existing module
   - New feature: Create new module in appropriate category
   - New variant: Add to `packages/newname.nix`

2. **Make changes in Nix file**
   - Add Lua code to `lua` field
   - Add plugins to `vimPackages`
   - Add packages to `packages`
   - Use `keymapd()` for which-key integration

3. **Test locally**
   ```bash
   nix run .                    # Test
   NVIM_DEBUG=1 nix run . | less # Debug view
   ```

4. **Commit and push**
   - Changes automatically available via `nix run github:...`

## Common Gotchas

1. **Forgot to add module to packages definition** → Feature doesn't load
   - Fix: Add module name to `packages/complete.nix` (or variant)

2. **Plugin not found** → `pkgs.vimPlugins.plugin-name` doesn't exist
   - Fix: Check nixpkgs for correct name, or build custom plugin

3. **Keymap not in which-key** → Used `keymap()` instead of `keymapd()`
   - Fix: Use `keymapd()` and always provide description

4. **Lua error on startup** → Syntax error in Lua code
   - Fix: Check with `NVIM_DEBUG=1` to see full generated file

5. **Missing system dependency** → LSP server not in PATH
   - Fix: Add to `packages = with pkgs; [ ... ]` in module

