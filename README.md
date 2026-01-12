# Neovim config in nix

Starting on this template to get my neovim configuration working with nix.

This template gives you a good starting point and hopefully a more lua driven
and simple/clear process for working with neovim.

## Configuring

To start configuring, just add or modify the nix files in `./config`.
If you add a new configuration file, remember to add it to the
[`config/default.nix`](./config/default.nix) file

### Testing your new configuration

To test your configuration simply run the following command

```bash
nix run .
```

## Nix Setup

This Neovim configuration is built entirely with Nix, providing reproducible, declarative editor configuration. The system
uses a modular architecture that allows you to compose different feature sets based on your needs.

### Nix Modules

The configuration uses a custom module system built on top of Nix flakes. Each module can define:
- **Lua configuration**: Neovim configuration code executed on startup
- **After Lua**: Lua code that runs after all other modules are loaded
- **Vim packages**: Neovim plugins to install
- **System packages**: External dependencies (LSP servers, formatters, etc.)
- **Imports**: Dependencies on other modules

Modules are organized into two directories:
- `common/`: Core features loaded in all configurations (greeter, terminal, file explorer, keymaps)
- `options/`: Optional features organized by category (lsp/, ai/, tools/)

The module system automatically handles dependency resolution, merging Lua configurations in the correct order, and
collecting all required packages. Each module's Lua code is wrapped with BEGIN/END markers for easier debugging.

### Packages

The `packages/` directory defines different Neovim distributions, each including a specific set of features. You can run
any of these packages directly using Nix:

**Available Packages**:

- **complete** (default): Full-featured configuration with all LSP servers, AI agents, and development tools
  - All language servers (Rust, Python, Go, TypeScript, Nix, Haskell, Kotlin, Zig, D)
  - Complete AI integration (agent system, Copilot, OpenCode)
  - All development tools (debugging, testing, database, coverage)

- **minimal**: Lightweight configuration with just essential tools
  - No LSP servers or AI features
  - Core development tools and UI enhancements only
  - Ideal for quick edits or resource-constrained environments

- **python**: Python-focused development environment
  - Python LSP servers with formatting and linting
  - All development tools
  - AI assistance (Copilot)
  - Great starting point for Python development

- **ai**: AI and LSP development configuration
  - All language servers for multi-language development
  - Complete AI tooling but excludes some specialized tools
  - Balanced between features and startup time

**Running from GitHub**:

You can run any package variant directly from the GitHub repository without cloning:

```bash
# Run the default (complete) configuration
nix run github:mikekwright/nixvim

# Run a specific package variant
nix run github:mikekwright/nixvim#minimal
nix run github:mikekwright/nixvim#python
nix run github:mikekwright/nixvim#ai
```

**Local Development**:

When working on the configuration locally, use:

```bash
# Run the default package
nix run .

# Run a specific variant
nix run .#minimal
nix run .#python
nix run .#ai

# Enable debug output to see generated Lua config
NVIM_DEBUG=1 nix run .
```

**Creating Custom Packages**:

To create your own package variant:

1. Create a new file in `packages/` (e.g., `packages/myconfig.nix`)
2. Define which modules to include using `lib.makeIncludes`:
   ```nix
   { lib, ... }:

   lib.makeIncludes {
     complete = [
       "lsp"
       "lsp.python"
       "tools"
       "ai.copilot"
     ];
   }
   ```
3. Add the package to `flake.nix` in the `packages` attribute set
4. Run with `nix run .#myconfig`

The packaging system ensures that only the specified modules and their dependencies are included, keeping each variant
focused and efficient. All packages share the same common foundation but can be customized for different use cases.


## Common Features

### Terminal

The terminal integration provides a persistent, shared terminal buffer that can be opened in multiple layouts without losing
your shell session or history.

**Terminal Modes**:
- **Fullscreen**: Opens the terminal as the main buffer, replacing your current view
- **Split**: Opens in a horizontal split above your current buffer
- **VSCode-style**: Opens at the bottom of the screen taking 25% of the vertical space

The same terminal buffer is reused across all modes, so you can switch between layouts without losing your shell session.
When you close a terminal window, the buffer remains active in the background, preserving your working directory, environment,
and command history.

**Terminal Features**:
- Double-tap `<Esc>` to exit insert mode while in the terminal
- Quick access with `<C-t>` for fullscreen mode
- Automatically enters insert mode when opening or switching to the terminal
- Integrates with Snacks terminal for enhanced functionality

All terminal commands are organized under `<leader>t` and accessible through which-key.

### Explorer

The file explorer uses nvim-tree to provide a feature-rich file navigation sidebar. The explorer automatically opens when
you launch Neovim from a directory and dynamically tracks your current file location.

**Key Features**:
- **Auto-tracking**: Automatically highlights the current file in the tree as you switch buffers
- **Dynamic sizing**: Maintains 15% of screen width and automatically adjusts when you resize the Neovim window
- **Smart filters**: Dotfiles are hidden by default but can be toggled with a keypress
- **File operations**: Full support for creating, renaming, copying, moving, and deleting files and directories
- **Bookmarks**: Mark frequently used files and directories for quick access
- **Live filtering**: Search and filter files in real-time within the tree
- **Git integration**: Navigate between git changes and filter by git clean status

The explorer uses standard vim navigation (j/k) and provides extensive file operations through single-key commands when
focused. All operations support both files and directories, with visual feedback for git status, diagnostics, and file types
through icons.

Explorer commands are organized under `<leader>e` and include toggles for the tree, filters, and file tracking. Press `g?`
while in the tree to see all available keybindings.

### Greeter

The greeter provides a welcoming dashboard when you launch Neovim without opening a specific file. It displays an ASCII art
NEOVIM logo and presents quick-access actions to get you started.

**Dashboard Actions**:
The greeter includes several built-in actions accessible via single-key shortcuts:
- Open the file explorer
- Create a new file
- Launch the AI agent
- Quit Neovim

The greeter uses a plugin-based registration system, allowing different parts of the configuration to add their own custom
actions to the dashboard. Actions are automatically sorted alphabetically by their key binding for consistent presentation.

When you open Neovim from a directory, the greeter is automatically replaced by the file explorer. The greeter only appears
when launching Neovim without any file arguments, providing a clean starting point for new editing sessions.


## LSP Features

Language Server Protocol (LSP) integration provides intelligent code editing capabilities across multiple programming
languages. The configuration uses Neovim's native LSP client with enhanced completion and diagnostic features.

### Completion

The completion system uses Blink.cmp as the primary completion engine, providing fast and intelligent code suggestions with
minimal latency. Completion sources are intelligently combined to offer the most relevant suggestions based on context.

**Completion Sources**:
- **LSP**: Language-specific completions from LSP servers
- **Path**: File system path completions
- **Copilot**: AI-powered code suggestions from GitHub Copilot
- **Avante**: Additional AI completions
- **Snippets**: Code snippet expansions
- **Buffer**: Words from open buffers
- **Emoji**: Emoji completions triggered by `:`

**Features**:
- **Auto-documentation**: Displays function signatures and documentation automatically after a short delay
- **Ghost text**: Shows completion preview inline at the cursor
- **Smart filtering**: Context-aware completion filtering and ranking
- **Configurable disable**: Can be disabled globally or in specific contexts (terminals, AI prompt windows)
- **Multiple accept keys**: Accept completions with `<Enter>`, `<Tab>`, or `<C-l>`

The completion engine integrates seamlessly with all configured LSP servers, automatically advertising supported capabilities
and providing consistent behavior across different file types. Documentation can be scrolled with arrow keys, and completions
can be navigated with `<C-j>` and `<C-k>`.

All completion settings are accessible under `<leader>l` through which-key, including a toggle to enable/disable completion
globally.

### Copilot

GitHub Copilot integration provides AI-powered code suggestions through the completion system. Copilot runs as a background
service and contributes suggestions to the unified completion menu alongside LSP and other sources.

**Configuration**:
- Copilot suggestions appear in the completion menu with high priority
- Shows up to 10 suggestions per request
- Disabled by default in certain file types (YAML, markdown, version control commit messages)
- Panel mode disabled in favor of inline completions

The Copilot integration requires Node.js and uses the copilot.lua plugin for Neovim-native implementation. Suggestions are
ranked and displayed alongside other completion sources, with visual indicators to distinguish AI-generated completions.

Copilot can be toggled on or off per session, with the state persisted until Neovim is restarted. The toggle command is
available under `<leader>lec` and provides immediate feedback about the current state.

### LSP Capabilities

The LSP system provides comprehensive language intelligence through configured language servers. Each LSP server is
automatically configured with optimal settings and integrated with the completion system.

**Supported Languages**:
Multiple language servers are pre-configured including Rust (rust-analyzer), Python (multiple servers), TypeScript/JavaScript,
Go (gopls), Nix (nixd, nil_ls), Haskell, Kotlin, Zig, D, and Markdown.

**Code Navigation**:
- **Go to definition**: Jump to where symbols are defined
- **Go to implementation**: Navigate to interface implementations
- **Go to type definition**: View type declarations
- **Find references**: Locate all usages of a symbol
- **Document symbols**: Browse all symbols in the current file
- **Workspace symbols**: Search symbols across the entire project

**Code Intelligence**:
- **Hover information**: View documentation and type information
- **Signature help**: Display function signatures while typing
- **Code actions**: Quick fixes and refactoring suggestions
- **Rename refactoring**: Rename symbols across the project
- **Document formatting**: Format code according to language conventions
- **Code lens**: Show inline metadata like test status or reference counts

**Diagnostics**:
- **Real-time errors**: Immediate feedback on syntax and semantic errors
- **Trouble integration**: View all diagnostics in a focused window
- **Inline diagnostics**: Error messages displayed at cursor position
- **Diagnostic navigation**: Jump between errors and warnings

LSP keymaps are dynamically registered based on server capabilities. Only features supported by the active language server
for the current buffer will have keymaps registered. All LSP commands are organized under `<leader>l` for consistency.

The LSP system integrates with Snacks picker for advanced navigation features like finding references and symbols with
fuzzy search and preview capabilities.


## AI Agent

This configuration includes comprehensive AI agent integration, allowing you to interact with various AI assistants directly
from Neovim. All AI agent keymaps are organized under `<leader>a` and are discoverable through which-key.

The AI agent system supports multiple agents including Claude Code, GitHub Copilot CLI, Cursor CLI, ChatGPT CLI, Gemini CLI,
and OpenCode. Each agent runs in a persistent terminal buffer that can be managed through various window layouts.

### Agent Selection

You can configure different AI agents on a per-project basis. The system remembers your agent preference for each working
directory and automatically restores it when you return to that project. Agent preferences are stored in a configuration
file at `~/.config/nvim-ai-config.json`.

Use the agent picker to switch between available agents at any time. Your selection will be saved and persist across
Neovim sessions for the current project directory.

### Agent Terminal

The agent terminal provides a dedicated buffer for interacting with your selected AI agent. The terminal can be opened in
various modes:

- Full-screen terminal that replaces the current buffer
- Vertical split alongside your working files
- As part of the agent mode layout

The terminal buffer is persistent and can be hidden or shown without losing your conversation history. You can restart the
agent, send interrupts, or exit the agent entirely through dedicated commands.

### Prompt Window

The prompt window is a composable workspace for crafting messages to send to your AI agent. It operates in two modes:

**Floating Mode**: Opens as a centered floating window (80% of screen size) with a rounded border, perfect for quick
interactions without disrupting your layout.

**Split Mode**: Opens as a regular split window that integrates into your window layout, ideal for keeping the prompt
visible during extended agent interactions.

The prompt window supports:
- Markdown syntax highlighting for better readability
- Sending visual selections wrapped in code blocks
- Inserting file paths at the cursor position
- Persistent content when hidden (only cleared on submission)
- Toggle between floating and split modes on the fly

Content sent to the prompt is inserted at the cursor position, allowing you to compose complex multi-part prompts by
combining code selections, file paths, and your own text.

### Agent Mode Layout

Agent mode creates a specialized three-panel layout optimized for AI-assisted development:

**Layout Structure**:
- Left side (75% width): Your main working buffer for editing code
- Right top (25% width, 75% height): Agent terminal showing AI responses
- Right bottom (25% width, 25% height): Prompt window for composing messages

This layout keeps everything visible at once - you can edit code, see agent responses, and compose new prompts without
switching windows. The prompt window in this layout automatically operates in split mode and clears content after
submission while remaining visible for your next prompt.

The agent mode layout reuses existing agent terminal and prompt buffers if they exist, preserving your conversation
history and any drafted prompt text.

## References

* [Learn Lua X in Y minutes](https://learnxinyminutes.com/docs/lua/)

* [Neovim Documentation](https://neovim.io/doc/user/builtin.html)

* [Youtube - Setting up Neovim from scratch with tmux](https://www.youtube.com/watch?v=ZjMzBd1Dqz8)
* [Github - Nixvim Repo](https://github.com/nix-community/nixvim/blob/main/plugins/filetrees/nvim-tree.nix)
* [Github - Nvim-tree repo](https://github.com/nvim-tree/nvim-tree.lua/blob/master/doc/nvim-tree-lua.txt)
* [Github - Strong nixvim flake example](https://github.com/pete3n/nixvim-flake)
* [Article - Nixvim with home manager and custom vim plugin](https://valentinpratz.de/posts/2024-02-12-nixvim-home-manager/)
* [Youtube - Simple series on configuring Neovim](https://www.youtube.com/watch?v=zHTeCSVAFNY)
* [Github - Another nvim example](https://github.com/elythh/nixvim)

## TODOs

* Install [Statuscol which gives a left side status column](https://github.com/luukvbaal/statuscol.nvim)
* Look at [Nightfly color scheme](https://github.com/bluz71/vim-nightfly-colors)
* Install [k8s support](https://github.com/Ramilito/kubectl.nvim)
* Decide [Should I use the auto-session (project kind of)](https://github.com/rmagatti/auto-session)
* Look at [Surround that helps surround text](https://github.com/kylechui/nvim-surround)
* Try out COC [Conquer of Completion](https://github.com/neoclide/coc.nvim)
* Can also see [Jira plugin for neovim](https://github.com/Arekkusuva/jira-nvim)
