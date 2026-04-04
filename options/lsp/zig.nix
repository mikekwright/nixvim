{ pkgs, ... }:

let
  name = "lsp.zig";

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
          id = 'zig',
          label = 'Zig',
          filetypes = { 'zig', 'zir' },
          root_markers = { 'build.zig' },
      launch_types = { 'zig', 'codelldb', 'lldb' },
          guidance = table.concat({
            'Zig debugging:',
            '  - Build the project first so the target binary exists.',
            '  - This setup uses codelldb or lldb-dap when available.',
            '  - Start with <leader>dc after selecting the built executable.',
          }, '\n'),
          templates = {
            ['dap.lua'] = [=[return function(ctx)
      local dap = ctx.dap
      local root = ctx.root

      dap.configurations.zig = {
        {
      type = "zig",
          request = "launch",
          name = "Zig executable",
          program = root .. "/zig-out/bin/your-app",
          cwd = root,
          stopOnEntry = false,
        },
      }
    end
    ]=],
            ['launch.json'] = [=[{
      "version": "0.2.0",
      "configurations": [
        {
          "name": "Zig executable",
      "type": "zig",
          "request": "launch",
          "program": "''${workspaceFolder}/zig-out/bin/your-app",
          "cwd": "''${workspaceFolder}",
          "stopOnEntry": false
        }
      ]
    }
    ]=],
          },
        })

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

          local adapter_path = first_executable({
            'codelldb',
            '${pkgs.lldb}/bin/codelldb',
            '${pkgs.lldb}/bin/lldb-dap',
            '${pkgs.lldb}/bin/lldb-vscode',
          })

          if adapter_path then
            local adapter_type = adapter_path:match('lldb%-dap$') and 'executable' or 'server'
            if adapter_type == 'server' then
              local adapter_port = 13001
              dap.adapters.zig = {
                type = 'server',
                port = adapter_port,
                executable = {
                  command = adapter_path,
                  args = { '--port', tostring(adapter_port) },
                },
              }
            else
              dap.adapters.zig = {
                type = 'executable',
                command = adapter_path,
              }
            end

            dap.configurations.zig = {
              {
                name = 'Zig: Launch executable',
                type = 'zig',
                request = 'launch',
                program = function()
                  return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/zig-out/bin/', 'file')
                end,
                cwd = function()
                  return vim.fn.getcwd()
                end,
                stopOnEntry = false,
              },
            }
          end
        end

        vim.lsp.config('zls', {
          cmd = { "zls" },
          filetypes = { "zig", "zir" },
          root_markers = { "build.zig", ".git" },
          single_file_support = true,
        })
        vim.lsp.enable('zls')
  '';
in
{
  inherit lua name;

  vimPackages =
    let
      zig.vim = pkgs.vimUtils.buildVimPlugin {
        name = "zig.vim";
        src = pkgs.fetchFromGitHub {
          owner = "ziglang";
          repo = "zig.vim";
          # Date is Sept 11, 2025
          rev = "0c100863c7901a79d9c4b7a2092e335cc09337cc";
          sha256 = "sha256-6ARj5+7ceLagu3hJ39NL9WaFSG3Y0PCEbF50/vy5t6w=";
        };
      };
    in
    [
      zig.vim
    ]
    ++ (with pkgs.vimPlugins; [
      neotest-zig
    ]);

  packages = with pkgs; [
    zig
    zls
    lldb
  ];
}
