{ pkgs, ... }:
let
  name = "lsp.rust";

  lua = /* lua */ ''
    local register_debug_guidance = _G.register_debug_guidance or function(filetypes, message)
      _G.debug_guidance_registry = _G.debug_guidance_registry or {}
      if type(filetypes) == "string" then
        filetypes = { filetypes }
      end

      for _, filetype in ipairs(filetypes) do
        _G.debug_guidance_registry[filetype] = message
      end
    end

    register_debug_guidance({ 'rust' }, table.concat({
      'Rust debugging:',
      '  - Build the crate with cargo so the target binary exists.',
      '  - Add a codelldb or lldb-vscode dap adapter for this machine/project.',
      '  - Start with <leader>dc after selecting the binary or launch configuration.',
    }, '\n'))

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
    lldb
  ];
}
