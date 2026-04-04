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
              '  - Use <leader>dC to create a project-local .nvim/dap.lua or .vscode/launch.json and point it at your adapter.',
              '  - Build the project first so the target binary and package context exist.',
            }, '\n'),
            templates = {
              ['dap.lua'] = [=[return function(ctx)
      local dap = ctx.dap
      local root = ctx.root

      dap.adapters.haskell = {
        type = "executable",
        command = "haskell-debug-adapter",
      }

      dap.configurations.haskell = {
        {
          type = "haskell",
          request = "launch",
          name = "Haskell executable",
          workspace = root,
          startup = root .. "/app/Main.hs",
          stopOnEntry = false,
        },
      }
    end
    ]=],
              ['launch.json'] = [=[{
      "version": "0.2.0",
      "configurations": [
        {
          "name": "Haskell executable",
          "type": "haskell",
          "request": "launch",
          "workspace": "''${workspaceFolder}",
          "startup": "''${workspaceFolder}/app/Main.hs",
          "stopOnEntry": false
        }
      ]
    }
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
  ];
}
