{ pkgs, ... }:

let
  name = "lsp.python";

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

    local function resolve_python_binary()
      local candidates = {
        vim.g.python3_host_prog,
        os.getenv("VIRTUAL_ENV") and (os.getenv("VIRTUAL_ENV") .. '/bin/python'),
        'python3',
        'python',
      }

      for _, candidate in ipairs(candidates) do
        if type(candidate) == 'string' and candidate ~= "" and vim.fn.executable(candidate) == 1 then
          return candidate
        end
      end
    end

    register_debug_guidance({ 'python' }, table.concat({
      'Python debugging:',
      '  - Install a Python interpreter with debugpy available.',
      '  - Then use require("dap-python").setup(<python>) once your adapter is resolved.',
      '  - Start with <leader>dc, use breakpoints (<leader>db>) and UI (<leader>du>).',
    }, '\n'))

    local dap_python_ok, dap_python = pcall(require, 'dap-python')
    if dap_python_ok then
      local python = resolve_python_binary()
      if python then
        local ok, err = pcall(dap_python.setup, python)
        if not ok then
          dprint('Could not initialize nvim-dap-python with ' .. python .. ': ' .. tostring(err))
        end

        local dap_ok, dap = pcall(require, 'dap')
        if dap_ok then
          dap.configurations.python = {
            {
              type = 'python',
              request = 'launch',
              name = 'Python: Current file',
              program = "''${file}",
              pythonPath = python,
              cwd = "''${workspaceFolder}",
              console = 'integratedTerminal',
              justMyCode = false,
            },
            {
              type = 'python',
              request = 'launch',
              name = 'Python: Pytest current file',
              module = 'pytest',
              args = { "''${file}" },
              pythonPath = python,
              cwd = "''${workspaceFolder}",
              console = 'integratedTerminal',
              justMyCode = false,
            },
          }
        end
      end
    end

    vim.lsp.config('pyright', {
      settings = {
        pyright = {},
      },
    })
    vim.lsp.enable('pyright')

    if neotest_adapters then
      table.insert(neotest_adapters, require("neotest-python")({
        dap = { justMyCode = false },
      }))
    end
  '';
in
{
  inherit lua name;

  vimPackages = with pkgs.vimPlugins; [
    nvim-dap-python
    neotest-python
  ];

  packages = with pkgs; [
    pyright
    python311Packages.debugpy
  ];
}
