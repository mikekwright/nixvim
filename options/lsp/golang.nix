{ pkgs, ... }:

let
  name = "lsp.golang";

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
              id = 'go',
              label = 'Go',
              filetypes = { 'go' },
              root_markers = { 'go.mod' },
              launch_types = { 'go' },
          guidance = table.concat({
            'Go debugging:',
            '  - Install delve (`dlv`) and set up a dap adapter/configuration.',
            '  - Project-local overrides live in .nvim/dap.lua.',
            '  - Build a debug-friendly binary before launch when your project needs explicit build steps.',
            '  - Use <leader>db for breakpoints and <leader>du for scopes, stacks, and watches.',
          }, '\n'),
          templates = {
            ['dap.lua'] = [=[return function(ctx)
              local dap = ctx.dap
              local root = ctx.root
              local project_dir = root
              local binary = project_dir .. "/.nvim/debug/app"
              local project_name = "Go project"

                  dap.configurations.go = {
                    {
                      type = "go",
                      request = "launch",
                      name = project_name,
                      cwd = project_dir,
                      mode = "exec",
                      program = function()
                        vim.notify("Building " .. project_name .. "...")
                        vim.fn.mkdir(project_dir .. "/.nvim/debug", "p")
                        local result = vim.system(
                          { "go", "build", "-gcflags=all=-N -l", "-o", binary, "." },
                          { cwd = project_dir, text = true }
                        ):wait()

                        if result.code ~= 0 then
                          error("go build failed:\n" .. (result.stderr or result.stdout or ""))
                        end

                        return binary
                      end,
                      console = "integratedTerminal",
                },
              }
            end
            ]=],
          },
        })

            local dap_go_ok, dap_go = pcall(require, 'dap-go')
            if dap_go_ok then
              local delve_path = '${pkgs.delve}/bin/dlv'
              if vim.fn.executable(delve_path) == 1 then
                local ok, err = pcall(dap_go.setup, {
                  delve = {
                    path = delve_path,
                  },
                })
                if not ok then
                  dprint('Could not initialize nvim-dap-go: ' .. tostring(err))
                end

                local dap_ok, dap = pcall(require, 'dap')
                if dap_ok then
                  dap.configurations.go = {
                    {
                      type = 'go',
                      name = 'Go: Debug current file',
                      request = 'launch',
                      program = "''${file}",
                      cwd = "''${workspaceFolder}",
                      console = 'integratedTerminal',
                    },
                    {
                      type = 'go',
                      name = 'Go: Debug package',
                      request = 'launch',
                      program = "''${workspaceFolder}",
                      cwd = "''${workspaceFolder}",
                      console = 'integratedTerminal',
                    },
                    {
                      type = 'go',
                      name = 'Go: Debug current test file',
                      request = 'launch',
                      mode = 'test',
                      program = "''${file}",
                      cwd = "''${workspaceFolder}",
                      console = 'integratedTerminal',
                    },
                  }
                end
              end
            end

            vim.lsp.config('gopls', {
              cmd = { '${pkgs.gopls}/bin/gopls' },
              filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
            })
            vim.lsp.enable('gopls')

            local golang_neotest_config = { -- Specify configuration
              go_test_args = {
                "-v",
                "-race",
                "-count=1",
                "-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out",
              },
            }
            if neotest_adapters then
              table.insert(neotest_adapters, require("neotest-golang")(golang_neotest_config))
            end
  '';
in
{
  inherit lua name;

  vimPackages = with pkgs.vimPlugins; [
    vim-go
    neotest-golang
    nvim-dap-go
  ];

  startScript = /* bash */ ''
    unset GOROOT
  '';

  packages = with pkgs; [
    go
    gotools
    delve

    # This is the language server for Go
    gopls
  ];
}
