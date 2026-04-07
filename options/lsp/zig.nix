{ pkgs, ... }:

let
  name = "lsp.zig";
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
      id = 'zig',
      label = 'Zig',
      filetypes = { 'zig', 'zir' },
      root_markers = { 'build.zig' },
      launch_types = { 'zig', 'codelldb', 'lldb' },
      guidance = table.concat({
        'Zig debugging:',
        '  - Build the project first so the target binary exists.',
        '  - This setup uses codelldb or lldb-dap when available.',
        '  - Project-local overrides live in .nvim/dap.lua.',
        '  - Start with <leader>dc after selecting the built executable.',
      }, '\n'),
      templates = {
        ['dap.lua'] = [=[return function(ctx)
          local dap = ctx.dap
          local root = ctx.root
          -- If the project is a subdir, add like belo
          local project_dir = root .. "/hello-world"
          -- local project_dir = root
          -- This should be setup
          local binary = "zig-out/bin/hello_world"
          local project_name = "Hello World"

          dap.configurations.zig = {
            {
              type = "zig",
              request = "launch",
              name = project_name,
              cwd = project_dir,
              program = function()
                vim.notify("Building " .. project_name .. "...")
                local result = vim.system(
                  { "zig", "build", "-Doptimize=Debug" },
                  { cwd = project_dir, text = true }
                ):wait()

                if result.code ~= 0 then
                  error("zig build failed:\n" .. (result.stderr or result.stdout or ""))
                end

                if vim.uv.os_uname().sysname == "Darwin" then
                  vim.notify("Generating DSymutil " .. project_name .. "...")
                  local result = vim.system(
                    { "dsymutil", binary },
                    { cwd = project_dir, text = true }
                  ):wait()

                  if result.code ~= 0 then
                    error("Failed to build symbols :\n" .. (result.stderr or result.stdout or ""))
                  end
                end

                return project_dir .. "/" .. binary
              end,
              runInTerminal = false,
              stopOnEntry = true,
            },
          }
        end
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
            '${codelldb}/bin/codelldb',
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
            runInTerminal = true,
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
    codelldb
    lldb
  ];
}
