{ pkgs, ... }:
let
  name = "lsp.typescript";

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
          id = 'javascript',
          label = 'JavaScript',
          filetypes = { 'javascript', 'javascriptreact' },
          root_markers = { 'package.json' },
          launch_types = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node', 'node2', 'node-terminal', 'pwa-extensionHost' },
          guidance = table.concat({
            'JavaScript debugging:',
            '  - Configure a node debug adapter (e.g., vscode-js-debug + nvim-dap-vscode-js).',
            '  - Launch with <leader>dc, toggle the UI with <leader>du, and inspect guidance with <leader>dg.',
          }, '\n'),
          templates = {
            ['dap.lua'] = [=[return function(ctx)
      local dap = ctx.dap
      local root = ctx.root

      local configurations = {
        {
          type = "pwa-node",
          request = "launch",
          name = "Node current file",
      program = "''${file}",
          cwd = root,
          console = "integratedTerminal",
          sourceMaps = true,
        },
      }

      dap.configurations.javascript = configurations
      dap.configurations.javascriptreact = configurations
    end
    ]=],
            ['launch.json'] = [=[{
      "version": "0.2.0",
      "configurations": [
        {
          "name": "Node: Current file",
          "type": "pwa-node",
          "request": "launch",
          "program": "''${file}",
          "cwd": "''${workspaceFolder}",
          "console": "integratedTerminal",
          "sourceMaps": true
        }
      ]
    }
    ]=],
          },
        })

        register_debug_language({
          id = 'typescript',
          label = 'TypeScript',
          filetypes = { 'typescript', 'typescriptreact' },
          root_markers = { 'tsconfig.json' },
          launch_types = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node', 'node2', 'node-terminal', 'pwa-extensionHost' },
          guidance = table.concat({
            'TypeScript debugging:',
            '  - Configure a node debug adapter (e.g., vscode-js-debug + nvim-dap-vscode-js).',
            '  - Launch with <leader>dc, toggle the UI with <leader>du, and inspect guidance with <leader>dg.',
          }, '\n'),
          templates = {
            ['dap.lua'] = [=[return function(ctx)
      local dap = ctx.dap
      local root = ctx.root

      local configurations = {
        {
          type = "pwa-node",
          request = "launch",
          name = "TypeScript current file",
      program = "''${file}",
          cwd = root,
          console = "integratedTerminal",
          sourceMaps = true,
        },
      }

      dap.configurations.typescript = configurations
      dap.configurations.typescriptreact = configurations
    end
    ]=],
            ['launch.json'] = [=[{
      "version": "0.2.0",
      "configurations": [
        {
          "name": "TypeScript: Current file",
          "type": "pwa-node",
          "request": "launch",
          "program": "''${file}",
          "cwd": "''${workspaceFolder}",
          "console": "integratedTerminal",
          "sourceMaps": true
        }
      ]
    }
    ]=],
          },
        })

        local dap_vscode_js_ok, dap_vscode_js = pcall(require, 'dap-vscode-js')
        if dap_vscode_js_ok then
          local node_path = vim.fn.exepath('node')
          local ok, err = pcall(function()
            dap_vscode_js.setup({
              node_path = node_path ~= "" and node_path or nil,
              adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' },
            })
          end)
          if not ok then
            dprint('Could not initialize nvim-dap-vscode-js: ' .. tostring(err))
          end

          local dap_ok, dap = pcall(require, 'dap')
          if dap_ok then
            local js_configurations = {
              {
                type = 'pwa-node',
                request = 'launch',
                name = 'Node: Current file',
                program = "''${file}",
                cwd = "''${workspaceFolder}",
                console = 'integratedTerminal',
                sourceMaps = true,
              },
              {
                type = 'pwa-node',
                request = 'launch',
                name = 'Node: Launch package script',
                runtimeExecutable = 'npm',
                runtimeArgs = { 'run', 'debug' },
                cwd = "''${workspaceFolder}",
                console = 'integratedTerminal',
                sourceMaps = true,
              },
              {
                type = 'pwa-node',
                request = 'attach',
                name = 'Node: Attach to 9229',
                cwd = "''${workspaceFolder}",
                port = 9229,
                sourceMaps = true,
              },
            }

            dap.configurations.javascript = js_configurations
            dap.configurations.javascriptreact = js_configurations
            dap.configurations.typescript = js_configurations
            dap.configurations.typescriptreact = js_configurations
          end
        end

        local default_node_debug = vim.fn.executable('node') == 1
        if not default_node_debug then
          register_debug_language({
            id = 'javascript',
            label = 'JavaScript',
            filetypes = { 'javascript', 'javascriptreact' },
            root_markers = { 'package.json' },
            launch_types = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node', 'node2', 'node-terminal', 'pwa-extensionHost' },
            guidance = table.concat({
              'JavaScript debugging:',
              '  - Node executable was not found in PATH, so runtime adapter setup was skipped.',
              '  - Install Node.js and a JS debug adapter (e.g. vscode-js-debug) to enable <leader>dc.',
            }, '\n'),
            templates = (_G.debug_language_registry and _G.debug_language_registry.javascript or {}).templates,
          })

          register_debug_language({
            id = 'typescript',
            label = 'TypeScript',
            filetypes = { 'typescript', 'typescriptreact' },
            root_markers = { 'tsconfig.json' },
            launch_types = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node', 'node2', 'node-terminal', 'pwa-extensionHost' },
            guidance = table.concat({
              'TypeScript debugging:',
              '  - Node executable was not found in PATH, so runtime adapter setup was skipped.',
              '  - Install Node.js and a JS debug adapter (e.g. vscode-js-debug) to enable <leader>dc.',
            }, '\n'),
            templates = (_G.debug_language_registry and _G.debug_language_registry.typescript or {}).templates,
          })
        end

        vim.lsp.config('eslint', {
          settings = {
            packageManager = 'yarn'
          },
        })
        vim.lsp.enable('eslint')

        require("typescript-tools").setup {
          -- on_attach = function() ... end,
          -- handlers = { ... },
          -- ...
          settings = {
            -- spawn additional tsserver instance to calculate diagnostics on it
            separate_diagnostic_server = true,
            -- "change"|"insert_leave" determine when the client asks the client about diagnostic
            publish_diagnostic_on = "insert_leave",
            -- array of strings("fix_all"|"add_missing_imports"|"remove_unused"|
            -- "remove_unused_imports"|"organize_imports") -- or string "all" to include all supported code actions
            -- to include all supported code actions
            -- specify commands exposed as code_actions
            expose_as_code_action = {},
            -- string|nil - specify a custom path to `tsserver.js` file, if this is nil or file under path
            -- not exists then standard path resolution strategy is applied
            tsserver_path = nil,
            -- specify a list of plugins to load by tsserver, e.g., for support `styled-components`
            -- (see 💅 `styled-components` support section)
            tsserver_plugins = {},
            -- this value is passed to: https://nodejs.org/api/cli.html#--max-old-space-sizesize-in-megabytes
            -- memory limit in megabytes or "auto"(basically no limit)
            tsserver_max_memory = "auto",
            tsserver_format_options = {},
            tsserver_file_preferences = {},
            -- locale of all tsserver messages, supported locales you can find here:
            -- https://github.com/microsoft/TypeScript/blob/3c221fc086be52b19801f6e825d04607ede6/src/compiler/utilitiesPublic.ts#L620
            tsserver_locale = "en",
            -- mirror of VSCode's `typescript.suggest.completeFunctionCalls`
            complete_function_calls = false,
            include_completions_with_insert_text = true,
            -- CodeLens
            -- WARNING: Experimental feature also in VSCode, because it might hit performance of screen.
            -- possible values: ("off"|"all"|"implementations_only"|"references_only")
            code_lens = "off",
            -- by default code lenses are displayed on all referencable values and for some of you it can
            -- be too much this option reduce count of them by removing member references from lenses
            disable_member_code_lens = true,
            -- JSXCloseTag
            -- WARNING: it is disabled by default (maybe you config or distro already uses nvim-ts-autotag,
            -- that maybe have a conflict if enable this feature. )
            jsx_close_tag = {
                enable = false,
                filetypes = { "javascriptreact", "typescriptreact" },
            }
          },
        }
        -- keymapd('<leader>lec', "LSP: Toggle Copilot", function()
        --   vim.g.copilot_enabled = not vim.g.copilot_enabled
        --   print("Copilot is now " .. (vim.g.copilot_enabled and "enabled" or "disabled"))
        -- end)
  '';
in
{
  inherit name lua;

  vimPackages = with pkgs.vimPlugins; [
    typescript-tools-nvim
    nvim-dap-vscode-js
  ];

  packages = with pkgs; [
    eslint_d

    typescript
    nodejs_22 # This is required for typescript
  ];
}
