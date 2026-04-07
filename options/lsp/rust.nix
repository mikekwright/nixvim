{ pkgs, ... }:
let
  name = "lsp.rust";
  codelldb = pkgs.vscode-extensions.vadimcn.vscode-lldb.adapter;

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
              id = 'rust',
              label = 'Rust',
              filetypes = { 'rust' },
              root_markers = { 'Cargo.toml' },
              launch_types = { 'codelldb', 'lldb', 'cppdbg', 'rust' },
          guidance = table.concat({
            'Rust debugging:',
            '  - Build the crate with cargo so the target binary exists.',
            '  - Add a codelldb or lldb-vscode dap adapter for this machine/project.',
            '  - Project-local overrides live in .nvim/dap.lua.',
            '  - Build before launch when your project produces a known binary path.',
          }, '\n'),
          templates = {
            ['dap.lua'] = [=[return function(ctx)
              local dap = ctx.dap
              local root = ctx.root
              local project_dir = root
              local binary = "target/debug/your-binary"
              local project_name = "Project binary"

                  dap.configurations.rust = {
                    {
                      type = "codelldb",
                      request = "launch",
                      name = project_name,
                      cwd = project_dir,
                      program = function()
                        vim.notify("Building " .. project_name .. "...")
                        local result = vim.system(
                          { "cargo", "build" },
                          { cwd = project_dir, text = true }
                        ):wait()

                        if result.code ~= 0 then
                          error("cargo build failed:\n" .. (result.stderr or result.stdout or ""))
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

            vim.g.rustaceanvim = {
              server = {
                on_attach = function(client, bufnr)
                  -- Your on_attach function here
                end,
                default_settings = {
                  -- rust-analyzer language server configuration
                  ['rust-analyzer'] = {
                    cmd = { "${pkgs.rust-analyzer}/bin/rust-analyzer" },
                    cargo = {
                      allFeatures = true,
                    },
                  },
                },
              },
              dap = {
                autoload_configurations = true,
              },
            }

            local dap_ok, dap = pcall(require, 'dap')
            if dap_ok then
              local function first_executable(candidates)
                for _, candidate in ipairs(candidates) do
                  local path = vim.fn.exepath(candidate)
                  if path ~= "" then
                    return path
                  end
                end
              end

              local codelldb_path = first_executable({
                '${codelldb}/bin/codelldb',
                'codelldb',
                '${pkgs.lldb}/bin/codelldb',
                '${pkgs.lldb}/bin/lldb-vscode',
                '${pkgs.lldb}/bin/lldb-dap',
              })

              if codelldb_path ~= nil then
                local codelldb_port = 13000
                dap.adapters.codelldb = {
                  type = 'server',
                  port = codelldb_port,
                  executable = {
                    command = codelldb_path,
                    args = { '--port', tostring(codelldb_port) },
                  },
                }

                dap.configurations.rust = {
                  {
                    name = 'Rust: Launch executable',
                    type = 'codelldb',
                    request = 'launch',
                    program = function()
                      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
                    end,
                    cwd = function()
                      return vim.fn.getcwd()
                    end,
                    runInTerminal = true,
                    stopOnEntry = false,
                  },
                  {
                    name = 'Rust: Launch current test binary',
                    type = 'codelldb',
                    request = 'launch',
                    program = function()
                      return vim.fn.input('Path to test binary: ', vim.fn.getcwd() .. '/target/debug/deps/', 'file')
                    end,
                    cwd = function()
                      return vim.fn.getcwd()
                    end,
                    runInTerminal = true,
                    stopOnEntry = false,
                  },
                }
              end
            end
  '';
in
{
  inherit lua name;

  vimPackages = with pkgs.vimPlugins; [
    rustaceanvim
  ];

  packages = with pkgs; [
    # This is the lsp server, but requires access to cargo and rustc
    rust-analyzer

    rustc
    #rustup
    cargo
    codelldb
    lldb
  ];
}
