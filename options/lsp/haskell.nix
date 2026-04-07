{ pkgs, ... }:
let
  name = "lsp.haskell";

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
                id = 'haskell',
                label = 'Haskell',
            filetypes = { 'haskell', 'lhaskell', 'cabal' },
                root_markers = { 'cabal.project', 'stack.yaml', 'package.yaml' },
                launch_types = { 'haskell' },
                guidance = table.concat({
                  'Haskell debugging:',
                  '  - Haskell DAP support is project-specific and usually depends on a haskell-debug-adapter setup.',
                  '  - Use <leader>dC to create a project-local .nvim/dap.lua and build before launch.',
                  '  - Build the project first so the target binary and package context exist.',
                }, '\n'),
                templates = {
                  ['dap.lua'] = [=[return function(ctx)
                    local dap = ctx.dap
                    local root = ctx.root
                    local project_dir = root
                    local project_name = "Haskell executable"

                    local function build_project()
                      local command = vim.uv.fs_stat(project_dir .. "/stack.yaml") and { "stack", "build" } or { "cabal", "build" }
                      vim.notify("Building " .. project_name .. "...")
                      local result = vim.system(command, { cwd = project_dir, text = true }):wait()
                      if result.code ~= 0 then
                        error(table.concat(command, " ") .. " failed:\n" .. (result.stderr or result.stdout or ""))
                      end
                    end

                    dap.adapters.haskell = {
                      type = "executable",
                      command = "haskell-debug-adapter",
                    }

                    dap.configurations.haskell = {
                      {
                        type = "haskell",
                        request = "launch",
                        name = project_name,
                        workspace = project_dir,
                        startup = function()
                          build_project()
                          return project_dir .. "/app/Main.hs"
                        end,
                        terminal = "integrated",
                        stopOnEntry = false,
                      },
                    }
                  end
                  ]=],
                },
              })

              vim.lsp.config('hls', {
                cmd = { '${pkgs.haskell-language-server}/bin/haskell-language-server-wrapper', '--lsp' },
            filetypes = { 'haskell', 'lhaskell', 'cabal' },
              })
              vim.lsp.enable('hls')
  '';
in
{
  inherit lua name;
  #
  # Maybe look at this tool in the future
  #   https://github.com/MrcJkb/haskell-tools.nvim
  #

  packages = with pkgs; [
    haskell-language-server
    cabal-install
    ghc
    stack
  ];
}
