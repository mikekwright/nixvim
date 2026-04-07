{ pkgs, ... }:

# Does not currently work (2025-11-27)
let
  name = "lsp.dlang";

  # Build vim-dlang-phobos-highlighter plugin from GitHub
  vim-dlang-phobos-highlighter = pkgs.vimUtils.buildVimPlugin {
    name = "vim-dlang-phobos-highlighter";
    src = pkgs.fetchFromGitHub {
      owner = "SirSireesh";
      repo = "vim-dlang-phobos-highlighter";
      rev = "11e24ea28c91fdf44df11ee0c9dbe4c001c5cc8a";
      sha256 = "sha256-qGhvVOzaXaGxHmJkr0xPCLFv8hnWpqPEhP3Gf9tNrdc=";
    };
  };

  lua = /* lua */ ''
            local register_debug_language = _G.register_debug_language or function(spec)
              if type(spec) ~= 'table' or type(spec.id) ~= 'string' then
                return
              end

              _G.debug_language_registry = _G.debug_language_registry or {}
              _G.debug_filetype_registry = _G.debug_filetype_registry or {}
              _G.debug_language_registry[spec.id] = spec

              for _, filetype in ipairs(spec.filetypes or {}) do
                _G.debug_filetype_registry[filetype] = spec.id
              end
            end

            register_debug_language({
              id = 'dlang',
              label = 'D',
              filetypes = { 'd', 'di' },
              root_markers = { 'dub.json', 'dub.sdl' },
              launch_types = { 'lldb', 'cppdbg', 'dlang' },
          guidance = table.concat({
            'D debugging:',
            '  - D debugging usually depends on an LLDB or GDB adapter plus your dub or ldc build output.',
            '  - Use <leader>dC to create project-local .nvim/dap.lua and wire in a build step before launch.',
            '  - Update the output binary path to match your dub configuration.',
          }, '\n'),
          templates = {
            ['dap.lua'] = [=[return function(ctx)
              local dap = ctx.dap
              local root = ctx.root
              local project_dir = root
              local binary = "bin/your-app"
              local project_name = "D executable"

              dap.configurations.d = {
                {
                  type = "lldb",
                  request = "launch",
                  name = project_name,
                  cwd = project_dir,
                  program = function()
                    vim.notify("Building " .. project_name .. "...")
                    local result = vim.system(
                      { "dub", "build", "--build=debug" },
                      { cwd = project_dir, text = true }
                    ):wait()

                    if result.code ~= 0 then
                      error("dub build failed:\n" .. (result.stderr or result.stdout or ""))
                    end

                    return project_dir .. "/" .. binary
                  end,
                  runInTerminal = false,
                  stopOnEntry = false,
                },
              }
            end
            ]=],
          },
        })

            -- Configure serve-d LSP using vim.lsp.config (Neovim 0.11+)
            vim.lsp.config('serve_d', {
              cmd = { "${pkgs.serve-d}/bin/serve-d" },
              filetypes = { "d", "di" },
              root_markers = { "dub.json", "dub.sdl", ".git" },
              single_file_support = true,
              -- Server-specific settings for serve-d
              settings = {
                d = {
                  -- Enable auto-formatting
                  enableFormatting = true,
                  -- Enable code actions
                  enableCodeActions = true,
                  -- Enable auto-imports
                  enableAutoImports = true,
                },
              },
            })

            -- Enable serve-d LSP
            vim.lsp.enable('serve_d')
  '';
in
{
  inherit lua name;

  vimPackages = [
    vim-dlang-phobos-highlighter
  ];

  packages = with pkgs; [
    # serve-d: D Language Server Protocol implementation
    serve-d

    # DMD: Official reference compiler for the D language
    dmd

    # DUB: Package and build manager for D programs and libraries
    dub
    gdb

    # LDC: LLVM-based D compiler (alternative to DMD, often faster)
    ldc

    # dtools: Ancillary tools for the D programming language
    # Includes: rdmd (run D programs like scripts), ddemangle, dustmite, etc.
    dtools
  ];
}
