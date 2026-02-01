# Nixvim Documentation Index

## Documentation Files

This directory contains comprehensive documentation about the nixvim project structure and configuration system.

### 1. STRUCTURE.md (START HERE FOR DEEP UNDERSTANDING)
**742 lines - Detailed Architecture Guide**

Comprehensive explanation of:
- How the module system works
- Detailed breakdown of all component types
- Common modules and their purpose
- Optional modules (LSP, AI, Tools)
- Keymap system and which-key integration
- How to add custom functionality (3 methods)
- Notification system (Noice)
- Plugin and package management
- Building and running instructions
- Configuration patterns and best practices

**Best for**: Understanding the system deeply, learning how to add features

### 2. QUICK_REFERENCE.md (START HERE FOR QUICK LOOKUP)
**285 lines - Quick Reference Guide**

Quick-access information:
- Directory structure table
- Module system overview diagram
- Module anatomy with examples
- Common keymaps reference
- Global utilities available
- Notification system quick guide
- Plugin management examples
- Testing and debugging commands
- Common gotchas and fixes
- Typical development workflow

**Best for**: Looking up commands, quick examples, troubleshooting

### 3. VISUAL_SUMMARY.txt (START HERE FOR HIGH-LEVEL VIEW)
**273 lines - ASCII Diagrams and Visual Overview**

Visual explanations:
- Execution flow diagram
- Directory organization chart
- Module anatomy with annotations
- Module loading sequence
- Key components and their roles
- Adding new functionality scenarios
- Notification system visual
- Keymap system table
- Testing and debugging commands
- Key patterns to remember

**Best for**: Getting a high-level understanding, visual learners

### 4. NOTES.md
**45 lines - Original project notes**

Early exploration notes about the nixvim setup.

### 5. README.md
**Empty placeholder file**

---

## Quick Start Reading Order

### If you have 5 minutes:
1. Read **VISUAL_SUMMARY.txt** (High-level overview with diagrams)

### If you have 15 minutes:
1. Read **VISUAL_SUMMARY.txt** (5 min)
2. Skim **QUICK_REFERENCE.md** (10 min)

### If you have 30+ minutes:
1. Read **VISUAL_SUMMARY.txt** (5 min)
2. Read **QUICK_REFERENCE.md** (10 min)
3. Read **STRUCTURE.md** (15+ min)

---

## Looking for Specific Information?

### "I want to understand the project architecture"
→ **STRUCTURE.md** (Section 1-3)

### "I want to add custom Lua code"
→ **STRUCTURE.md** (Section 7) or **QUICK_REFERENCE.md** (Module System Overview)

### "I want to use notifications"
→ **STRUCTURE.md** (Section 8) or **QUICK_REFERENCE.md** (Notification System)

### "I want to understand keybindings"
→ **STRUCTURE.md** (Section 6) or **QUICK_REFERENCE.md** (Keymap System)

### "I want to add a new plugin"
→ **STRUCTURE.md** (Section 9) or **QUICK_REFERENCE.md** (Plugin Management)

### "I want to add a new LSP language"
→ **STRUCTURE.md** (Section 5: Language Server Protocol)

### "I want to create a new package variant"
→ **README.md** (in project root) or **STRUCTURE.md** (Section 5)

### "I'm getting errors"
→ **QUICK_REFERENCE.md** (Common Gotchas)

### "I want to test my changes"
→ **QUICK_REFERENCE.md** (Testing & Debugging) or **STRUCTURE.md** (Section 11)

---

## Project Structure Overview

```
nixvim/
├── flake.nix                          # Entry point
├── lib/                               # Module infrastructure
│   ├── importer.nix                   # CORE system
│   ├── options.nix                    # Feature flags
│   └── debug.nix                      # Debug helpers
├── common/                            # Always-loaded features
│   ├── base.nix                       # Global helpers, keymap functions
│   ├── whichkey.nix                   # Help menu
│   ├── keymaps.nix, theme.nix, etc.
│   └── ...
├── options/                           # Conditional features
│   ├── lsp/                           # Language servers (by language)
│   ├── ai/                            # AI integration
│   └── tools/                         # Development tools
│       ├── noice.nix                  # Notifications
│       ├── snacks.nix                 # Feature hub
│       └── ...
├── packages/                          # Config variants
│   ├── complete.nix
│   ├── minimal.nix
│   ├── python.nix
│   └── ai.nix
└── docs/                              # Documentation (this folder)
    ├── STRUCTURE.md
    ├── QUICK_REFERENCE.md
    ├── VISUAL_SUMMARY.txt
    └── INDEX.md (this file)
```

---

## Key Concepts Quick Glossary

**Module**: A .nix file containing Lua code, plugins, packages, and imports. The basic building block.

**Importer**: `lib/importer.nix` - The core system that loads, merges, and compiles all modules into a single `init.lua`.

**Common Module**: A module marked with `common = true` that always gets loaded regardless of package.

**Optional Module**: A module that only loads if included in a package definition.

**Package**: A pre-configured Neovim variant (complete, minimal, python, ai).

**Which-key**: A plugin that shows discoverable command menus. All keymaps with descriptions auto-integrate.

**Noice**: The notification system (`options/tools/noice.nix`). Routes and displays `vim.notify()` messages.

**Snacks**: A versatile plugin that provides picker, zen mode, animations, terminal, indent, etc.

**LSP**: Language Server Protocol - provides code intelligence for specific languages.

**Plugin**: A Vim/Neovim plugin installed via `vimPackages`.

**Package**: (in Nix context) A system-level package (LSP server, formatter, tool) added to PATH.

---

## Common Tasks and Where to Find Them

| Task | Documentation |
|------|---|
| Add Lua code to existing module | STRUCTURE.md §7 Method 1 |
| Create new module | STRUCTURE.md §7 Method 2 |
| Add notification | STRUCTURE.md §8 |
| Add keymap | QUICK_REFERENCE.md Keymap Helpers |
| Install plugin | STRUCTURE.md §9 |
| Add LSP language | STRUCTURE.md §5 |
| Debug configuration | QUICK_REFERENCE.md Testing & Debugging |
| Create package variant | README.md (project root) or STRUCTURE.md §5 |
| Fix missing command | QUICK_REFERENCE.md Common Gotchas |

---

## Absolute File Paths

For complete list of absolute paths to key files, see the end of QUICK_REFERENCE.md or refer to STRUCTURE.md §12 (Key Files Reference).

---

## Getting Help

1. Check the appropriate documentation file above
2. Search in QUICK_REFERENCE.md for "Common Gotchas"
3. Look at similar existing modules for patterns
4. Review examples in `samples/` directory
5. Check the original README.md in project root

---

## Contributing to Documentation

When updating any of these docs:
- Keep VISUAL_SUMMARY.txt concise (ASCII diagrams only)
- Keep QUICK_REFERENCE.md scannable (tables and short entries)
- Keep STRUCTURE.md comprehensive (detailed explanations with examples)
- Update INDEX.md to reflect major changes

---

Last updated: 2025-01-31
