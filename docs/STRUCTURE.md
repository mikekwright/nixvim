# Nixvim Repository Structure and Configuration Overview

## 1. Project Architecture

This is a **declarative Neovim configuration system** built entirely with Nix Flakes. Rather than traditional Lua config files, this project uses Nix to compose, build, and manage a fully configured Neovim binary with all dependencies included.

### Core Philosophy
- **Declarative**: All configuration is defined through Nix files, not runtime scripts
- **Reproducible**: Same flake.nix produces identical Neovim binaries across systems
- **Modular**: Features are organized as composable modules that can be mixed and matched
- **Package-based**: Creates different pre-configured Neovim variants (complete, minimal, python, ai)

---

## 2. Directory Structure

```
/home/mikewright/Development/setup/nixvim/
├── flake.nix                 # Main entry point - defines inputs and outputs
├── lib/                      # Core infrastructure for module system
│   ├── importer.nix         # Module loading, merging, and compilation logic
│   ├── options.nix          # Feature flag system for conditional includes
│   └── debug.nix            # Debug helpers for development
├── common/                   # Always-included core features
│   ├── base.nix             # Global settings, keymap helpers, utilities
│   ├── whichkey.nix         # Help menu system for discovering keybinds
│   ├── keymaps.nix          # Core keybindings
│   ├── theme.nix            # Colors, appearance, UI elements
│   ├── terminal.nix         # Terminal buffer management
│   ├── greeter.nix          # Dashboard/welcome screen
│   ├── tree.nix             # File explorer (nvim-tree)
│   ├── funcs.nix            # Shared Lua utility functions
│   ├── git/                 # Git integration components
│   └── default.nix          # Imports all common modules
├── options/                 # Conditional/optional features
│   ├── lsp/                 # Language Server Protocol setup (by language)
│   │   ├── default.nix
│   │   ├── rust.nix, python.nix, typescript.nix, golang.nix, etc.
│   │   ├── formatting.nix   # Code formatting configuration
│   │   ├── dap.nix          # Debugging (DAP protocol)
│   │   └── neotest.nix      # Testing framework integration
│   ├── ai/                  # AI agent and completion features
│   │   ├── agent.nix        # AI agent system (Copilot CLI, Claude Code, etc.)
│   │   ├── copilot.nix      # GitHub Copilot integration
│   │   ├── avante.nix       # Avante AI plugin
│   │   ├── opencode.nix     # OpenCode AI integration
│   │   ├── agents/          # Individual agent configurations
│   │   └── default.nix
│   ├── tools/               # Development utilities and enhancements
│   │   ├── snacks.nix       # Main snacks.nvim configuration hub
│   │   ├── snacks/          # Sub-modules for snacks features
│   │   │   ├── picker.nix   # File/search picker (telescope alternative)
│   │   │   ├── animate.nix  # Animation engine
│   │   │   ├── zen.nix      # Focus mode
│   │   │   ├── terminal.nix # Terminal integration
│   │   │   ├── indent.nix   # Indent guides
│   │   │   ├── bigfile.nix  # Large file handling
│   │   │   └── ... (more snacks features)
│   │   ├── noice.nix        # Notification system (nvim-notify + noice)
│   │   ├── mini.nix         # Mini plugins collection
│   │   ├── debugging.nix    # Debugger setup
│   │   ├── testing.nix      # Test runner integration
│   │   ├── db.nix           # Database integration
│   │   └── ... (more tools)
│   └── default.nix
├── packages/                # Predefined Neovim configurations
│   ├── complete.nix         # Full-featured (all LSP, AI, tools)
│   ├── minimal.nix          # Lightweight (core only)
│   ├── python.nix           # Python-focused setup
│   └── ai.nix               # AI-centric configuration
├── samples/                 # Example projects for different languages
│   ├── rust/, python/, golang/, typescript/, zig/, etc.
│   └── README.md
└── docs/
    └── NOTES.md
```

---

## 3. Module System (Core Infrastructure)

### How Modules Work

Each Nix module is a separate file that defines optional configuration for Neovim. A module can contain:

**Module Structure** (from `common/base.nix` or `options/tools/noice.nix`):

```nix
{ pkgs, ... }:

let
  name = "module.name";           # Unique identifier
  lua = /*lua*/ ''                # Lua code to execute at startup
    -- Lua configuration here
  '';
in
{
  inherit name lua;
  
  # Optional: Lua code that runs AFTER all other modules load
  afterLua = /*lua*/ ''...'' or "";
  
  # Optional: Vim plugins to include
  vimPackages = with pkgs.vimPlugins; [
    plugin-name
  ];
  
  # Optional: System packages needed (LSP servers, formatters, etc.)
  packages = with pkgs; [
    package-name
  ];
  
  # Optional: Child modules to import/include
  imports = [
    ./submodule.nix
  ];
  
  # Special flag for common modules (always loaded)
  common = true;
}
```

### Module Loading Pipeline

1. **flake.nix** → Creates package variants using `lib.makeModule()`
2. **lib/importer.nix** → `makeModule()` orchestrates everything:
   - Recursively loads and merges all imported modules
   - Concatenates all Lua code in correct order (with BEGIN/END markers)
   - Collects all plugins (`vimPackages`)
   - Gathers all system packages
3. **lib/options.nix** → Feature flag filtering:
   - Checks if module is in `includes.complete` or `includes.extensions`
   - Conditionally includes modules based on package variant
4. **Final Output** → Single `init.lua` + plugins list + packages list

### Module Dependency Resolution

Modules can import other modules via the `imports` field:

```nix
{
  imports = [
    ./feature1.nix
    ./feature2.nix
  ];
}
```

The system recursively loads and merges all dependencies while avoiding duplicates.

---

## 4. Common Modules (Always Loaded)

These are in `/common/` and are loaded in every Neovim configuration:

### base.nix
- **Purpose**: Core setup and global utilities
- **Key Exports**:
  - Global variables: `vim.g.mapleader = ','`
  - Helper functions: `keymap()`, `keymapd()`, `nkeymap()`, `tkeymap()`, `xkeymapd()`, `vkeymapd()`, `ikeymapd()`
  - Editor options: line numbers, tabs (2 spaces), encoding, search behavior
  - Debug utilities: `dd()`, `bt()` functions using snacks

### whichkey.nix
- **Purpose**: Discoverable keybinding system
- **Exports**: Keymap groups and help menu
- **Key Groups Defined**:
  - `<leader>a` - AI tools
  - `<leader>b` - Buffer commands
  - `<leader>d` - Debug
  - `<leader>e` - Explorer/file tree
  - `<leader>f` - Find
  - `<leader>g` - Git
  - `<leader>h` - Help
  - `<leader>l` - LSP
  - `<leader>m` - Move/bookmark
  - `<leader>r` - Run
  - `<leader>t` - Terminal
  - `<leader>w` - Windows (proxied to `<C-w>`)

### keymaps.nix
- **Purpose**: Common keybindings used everywhere
- **Examples**:
  - `<leader>r` - Toggle relative line numbers
  - `<leader>cs` - Clear search highlights
  - `<C-w>` navigation in terminal mode
  - Buffer navigation: `<leader>bn`, `<leader>bp`, `<leader>bd`

### theme.nix
- **Purpose**: Visual appearance
- **Configures**: Color scheme, UI elements, statusline

### terminal.nix
- **Purpose**: Persistent terminal buffer management
- **Features**:
  - Shared terminal buffer usable in multiple layouts
  - Modes: fullscreen, split, VSCode-style
  - `<C-t>` for quick access
  - Double-tap `<Esc>` to exit insert mode

### greeter.nix
- **Purpose**: Welcome/dashboard screen
- **Features**:
  - Shows when opening Neovim without files
  - Plugin-based action registration system
  - Custom actions can be added by other modules

### tree.nix
- **Purpose**: File explorer (nvim-tree)
- **Features**:
  - Auto-track current file
  - Git status integration
  - Bookmarks for quick access
  - Commands under `<leader>e`

### git/
- **Components**:
  - `git/default.nix` - Main git integration
  - `git/git-diff.nix` - Diff visualization
  - `git/left-status.nix` - Left sidebar git status

### funcs.nix
- **Purpose**: Shared Lua utility functions
- **Current Utilities**:
  - `find_window_for_buffer(buf)` - Find window displaying a buffer

---

## 5. Optional Modules (in `/options/`)

These are conditionally included based on package configuration.

### Language Server Protocol (LSP)

**Structure**: `/options/lsp/` with one file per language or feature

**Files**:
- `rust.nix` - Rust/rust-analyzer setup
- `python.nix` - Python LSP servers (pylsp, pyright, ruff-lsp)
- `typescript.nix` - TypeScript/JavaScript (ts-ls, eslint)
- `golang.nix` - Go (gopls)
- `nix.nix` - Nix (nixd, nil_ls)
- `markdown.nix` - Markdown support
- `haskell.nix`, `kotlin.nix`, `zig.nix`, `dlang.nix` - Language-specific

**Common LSP Features**:
- Configured via `vim.lsp.config.*`
- Keymaps under `<leader>l`:
  - `<leader>ld` - Go to definition
  - `<leader>lh` - Hover documentation
  - `<leader>li` - Find implementations
  - `<leader>lr` - Rename symbol
  - `<leader>lf` - Format code
- Integration with Blink.cmp for completion

**Special LSP Modules**:
- `formatting.nix` - Code formatters (prettier, black, rustfmt, etc.)
- `dap.nix` - Debugging (DAP protocol support)
- `neotest.nix` - Testing framework integration

### AI Integration

**Structure**: `/options/ai/`

**Files**:
- `agent.nix` - Main AI agent system
  - Supports: Claude Code, GitHub Copilot CLI, Cursor CLI, ChatGPT, Gemini, OpenCode
  - Persistent terminal buffer for conversation
  - Prompt window for composing messages
  - Agent mode layout (3-panel specialized view)
  - Agent selection/persistence per project (`~/.config/nvim-ai-config.json`)
  
- `copilot.nix` - GitHub Copilot integration
  - Inline completions in Blink.cmp
  - Can be toggled per session
  
- `avante.nix` - Avante AI plugin
  - Alternative AI completion source
  
- `opencode.nix` - OpenCode integration
  - Latest Nixpkgs integration for OpenCode

- `agents/opencode-agent.nix` - Specific OpenCode configuration

### Development Tools

**Structure**: `/options/tools/`

**Major Components**:

#### snacks.nix (Meta-module)
Hub that imports and configures multiple Snacks.nvim features:
- **picker.nix** - File/symbol picker (telescope alternative)
  - File search: `<leader>ff`
  - Git files: `<leader>fg`
  - Recent files: `<leader>fr`
  - Diagnostics: `<leader>ld`
  - Uses ripgrep (`rg`) and fd
  
- **picker.nix** - Fuzzy finder with preview
  - File finding, searching, symbol browsing
  - Keymaps: `<leader>ff` (files), `<leader>fg` (git), etc.

- **terminal.nix** - Enhanced terminal handling
  - Alternative to built-in terminal.nix
  
- **animate.nix** - Animation effects
  - For visual feedback when opening windows, etc.
  
- **zen.nix** - Focus/zen mode
  - Distraction-free editing
  - Toggle: `<leader>sz`
  
- **indent.nix** - Visual indent guides
  - Toggles with `<leader>ei`
  
- **bigfile.nix** - Large file optimization
  - Auto-disables features for files >100KB
  
- **dim.nix** - Code dimming based on clock
  - Toggle: `<leader>sd`
  
- **gitbrowse.nix** - Open files in GitHub/GitLab
  - `<leader>gb` to open current file online
  
- **toggle.nix** - Global toggle system
  - Enable/disable various editor features
  
- **words.nix** - Word highlighting
  - Shows words under cursor throughout buffer
  
- **input.nix** - Input dialogs
  - Snacks-powered input prompts

#### noice.nix
**Notification and messaging system** (on-disk at `/options/tools/noice.nix`)
- Uses **nvim-notify** for popup notifications
- Uses **noice.nvim** for message routing and display
- Treesitter highlighting for all messages
- LSP progress display in mini window
- Customizable routing for different message types
- Keymap: `<leader>hn` to display all notification details

#### mini.nix
Collection of mini plugins:
- Pairs (auto-close brackets)
- Surround (work with surrounding delimiters)
- Align (text alignment)
- Comment (commenting)
- Various utilities

#### Other Tools
- **debugging.nix** - DAP-based debugging setup
- **testing.nix** - Test runner integration
- **db.nix** - Database integration
- **bqf.nix** - Better quickfix window
- **bookmarks.nix** - Bookmark management
- **coverage.nix** - Code coverage visualization
- **markit.nix** - Markdown utilities
- **electronics/** - Electronics/hardware-specific tools (platformio)

---

## 6. Keymap System

### Global Keymap Helpers

Defined in `common/base.nix`, all modules can use these:

```lua
-- Normal mode with silent, noremap
function keymap(key, action)
function keymapd(key, desc, action)  -- With description for which-key

-- Normal mode with noremap=true
function nkeymap(key, action)

-- Terminal mode
function tkeymap(key, action)
function tkeymapd(key, desc, action)

-- Visual/select mode
function xkeymapd(key, desc, action)
function vkeymapd(key, desc, action)

-- Insert mode
function ikeymapd(key, desc, action)
```

### Which-Key Integration

The `whichkey.nix` module registers all top-level groups. Individual modules can add subcommands:

```lua
keymapd("<leader>xy", "Description of command", "action or function")
```

The description automatically appears in which-key's menu.

---

## 7. Custom Lua Functionality - Adding Your Own

### Method 1: Add to Existing Module

If your code relates to an existing feature, modify that module's `lua` field:

```nix
{ pkgs, ... }:

let
  name = "tools.noice";
  
  lua = /*lua*/ ''
    -- Existing code here
    
    -- Your custom code
    keymapd("<leader>hc", "My Custom Command", function()
      -- Your Lua code
    end)
  '';
in
{
  inherit name lua;
  vimPackages = ...;
}
```

### Method 2: Create New Module

Create a new Nix file in `options/tools/` (or appropriate category):

**File**: `/home/mikewright/Development/setup/nixvim/options/tools/my-feature.nix`

```nix
{ pkgs, ... }:

let
  name = "tools.my-feature";
  
  lua = /*lua*/ ''
    -- Your custom Lua code
    keymapd("<leader>mf", "My Feature", function()
      vim.notify("Feature activated!")
    end)
  '';
  
  afterLua = /*lua*/ ''
    -- Code that runs AFTER everything else loads (if needed)
  '';
in
{
  inherit name lua;
  
  # Optional: if you need plugins
  vimPackages = with pkgs.vimPlugins; [
    -- plugin names
  ];
  
  # Optional: if you need system packages
  packages = with pkgs; [
    -- package names
  ];
  
  imports = [];
}
```

### Method 3: Add to Package Configuration

Edit the relevant package file to include your module:

**File**: `/home/mikewright/Development/setup/nixvim/packages/complete.nix`

```nix
{ lib, ... }:

lib.makeIncludes {
  complete = [
    "lsp"
    "lsp.python"
    "tools"
    "tools.my-feature"  # Add here
  ];
}
```

### Testing Your Module

```bash
# Run the complete package
nix run .

# Or with debug output to see generated Lua
NVIM_DEBUG=1 nix run .

# Or run a specific package
nix run .#minimal
```

---

## 8. Notification System (Noice)

The existing notification system is configured in `options/tools/noice.nix`:

### How to Send Notifications

In your Lua code:

```lua
-- Using vim.notify (routed to noice)
vim.notify("Message text", vim.log.levels.INFO)
vim.notify("Warning!", vim.log.levels.WARN)
vim.notify("Error!", vim.log.levels.ERROR)

-- Or directly using Snacks (if available)
require('snacks').notify("Message")
```

### Key Notification Features

- **Stages**: Fade in/out effect
- **Timeout**: 3000ms (3 seconds)
- **Bottom Display**: Messages appear at bottom, not top
- **Routing**: Different message types shown in different views:
  - Errors/warnings → popup notify boxes
  - LSP messages → mini window
  - Search messages → virtual text

### Custom Notification Routes

Add to `noice.nix` in the `routes` table to customize how specific message types display.

---

## 9. Plugin Management

### How Plugins Are Installed

1. **Define in module**: Add plugin name to `vimPackages` list
   ```nix
   vimPackages = with pkgs.vimPlugins; [
     plugin-name  # Must exist in nixpkgs
   ];
   ```

2. **Importer collects**: `lib/importer.nix` gathers all plugins from all modules

3. **Nix builds**: Plugins are included in the Neovim derivation
   ```nix
   packages.myVimPackage = {
     start = fullModule.vimPackages;  # Auto-loaded plugins
     opt = fullModule.vimOptPackages;  # Optional plugins
   };
   ```

4. **Result**: All plugins available in Neovim at runtime

### Finding Plugins

Check nixpkgs to see available plugins:
- Search: https://github.com/nixos/nixpkgs/blob/master/pkgs/applications/editors/vim/plugins/
- Or search: `pkgs.vimPlugins.<tab>`

### Adding Unofficial Plugins

If a plugin isn't in nixpkgs, you can build it locally:

```nix
let
  my-plugin = pkgs.vimUtils.buildVimPlugin {
    name = "my-plugin";
    src = pkgs.fetchFromGitHub {
      owner = "user";
      repo = "repo";
      rev = "v1.0.0";
      sha256 = "...";  # Get with `nix-prefetch-github user/repo`
    };
  };
in
{
  vimPackages = [ my-plugin ] ++ ...;
}
```

---

## 10. System Packages

### How System Packages Work

Packages like LSP servers, formatters, etc. are added to the global PATH when Neovim runs:

```nix
{
  packages = with pkgs; [
    rust-analyzer      # LSP server
    black             # Python formatter
    prettier          # JS/TS formatter
    ripgrep           # Fast search
    fd               # Fast find
  ];
}
```

These are wrapped in the `nvim` command via `runtimeInputs` in the shell wrapper.

### Common Package Dependencies

- **LSP Servers**: rust-analyzer, python-lsp-server, typescript-language-server, etc.
- **Formatters**: black, prettier, rustfmt, etc.
- **Tools**: ripgrep, fd, sqlite, git, etc.
- **Languages**: python, nodejs, go, rust, etc.

---

## 11. Building and Running

### Local Development

```bash
# Build and run the default (complete) package
cd /home/mikewright/Development/setup/nixvim
nix run .

# Run a specific variant
nix run .#minimal
nix run .#python
nix run .#ai

# With debug output (shows generated Lua)
NVIM_DEBUG=1 nix run . [file]
```

### Publishing to GitHub

The flake can be run remotely:

```bash
# Run from GitHub
nix run github:mikekwright/nixvim

# Run specific variant
nix run github:mikekwright/nixvim#python
```

### Building Standalone Package

```bash
# Build (creates ./result symlink)
nix build .

# Use the built Neovim
./result/bin/nvim
```

---

## 12. Key Files Reference

| File | Purpose |
|------|---------|
| `flake.nix` | Entry point, defines inputs, packages, systems |
| `lib/importer.nix` | Core module system - loading, merging, compilation |
| `lib/options.nix` | Feature flag system for conditional includes |
| `lib/debug.nix` | Debug utilities for development |
| `common/base.nix` | Core settings and helper functions |
| `common/whichkey.nix` | Keymap groups and help menu |
| `packages/*.nix` | Package variant definitions |
| `options/tools/noice.nix` | Notification system |
| `options/tools/snacks.nix` | Snacks.nvim hub configuration |
| `README.md` | User-facing documentation |

---

## 13. Configuration Patterns

### Pattern: Adding a Keymap with Description

```lua
keymapd("<leader>xx", "What this does", function()
  -- Your code here
  vim.notify("Action performed!")
end)
```

### Pattern: Conditional Features Within a Module

```lua
if vim.fn.has("nvim-0.11") == 1 then
  -- New feature code
else
  -- Fallback
end
```

### Pattern: Using Existing Helper Functions

```lua
-- From base.nix global helpers
keymap("<leader>custom", ":YourCommand<CR>")
keymapd("<leader>custom", "Description", function() end)

-- From funcs.nix
local win = find_window_for_buffer(buf)
```

### Pattern: Organizing Submenu Commands

```lua
-- Top-level group (in whichkey.nix)
{ "<leader>x", group = "Custom Group", desc = "My Commands" }

-- Individual commands in your module
keymapd("<leader>xa", "Action A", function() end)
keymapd("<leader>xb", "Action B", function() end)
-- These automatically appear under <leader>x in which-key
```

---

## 14. Summary

This is a sophisticated, reproducible Neovim configuration system built on Nix. Key characteristics:

- **Module-based**: Everything is a composable Nix module
- **Declarative**: Configuration is pure Nix, not runtime scripts
- **Reproducible**: Same flake = same Neovim everywhere
- **Package variants**: Different configurations for different needs
- **Lua-centric**: Actual editor config is in Lua, wrapped by Nix
- **Well-organized**: Clear separation between common, lsp, ai, and tools
- **Extensible**: Easy to add new modules without modifying existing code
- **Discoverable**: Which-key integration makes all commands discoverable

To add functionality, typically either:
1. Add Lua code to an existing module file
2. Create a new module file
3. Update package definitions to include the module
4. Test with `nix run .`

