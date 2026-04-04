{ pkgs, ... }:

let
  name = "tools.debugging";

  lua = /* lua */ ''
        _G.debug_guidance_registry = _G.debug_guidance_registry or {}
        _G.register_debug_guidance = _G.register_debug_guidance or function(filetypes, message)
          if type(filetypes) == "string" then
            filetypes = { filetypes }
          end

          for _, filetype in ipairs(filetypes) do
            _G.debug_guidance_registry[filetype] = message
          end
        end

        local dap = require('dap')
        local dapui = require('dapui')

        dapui.setup()

        dap.listeners.before.attach.dapui_config = function()
          dapui.open()
        end

        dap.listeners.before.launch.dapui_config = function()
          dapui.open()
        end

        dap.listeners.before.event_terminated.dapui_config = function()
          dapui.close()
        end

        dap.listeners.before.event_exited.dapui_config = function()
          dapui.close()
        end

        local function detect_debug_root(bufnr)
          local buffer_name = vim.api.nvim_buf_get_name(bufnr)
          local start_path = buffer_name ~= "" and vim.fs.dirname(buffer_name) or vim.uv.cwd()
          local root_markers = {
            'pyproject.toml',
            'setup.py',
            'Cargo.toml',
            'go.mod',
            'package.json',
            'tsconfig.json',
            '.git',
          }

          local root = vim.fs.find(root_markers, {
            path = start_path,
            upward = true,
            stop = vim.uv.os_homedir(),
          })[1]

          return root and vim.fs.dirname(root) or nil
        end

        local function build_cache_key(path)
          local stat = vim.uv.fs_stat(path)
          if not stat or not stat.mtime then
            return nil
          end

          return tostring(stat.mtime.sec) .. ':' .. tostring(stat.mtime.nsec or 0)
        end

        local launch_type_map = {
          ["python"] = { "python" },
          ["go"] = { "go" },
          ["pwa-node"] = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
          ["pwa-chrome"] = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
          ["pwa-msedge"] = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
          ["node"] = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
          ["node2"] = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
          ["node-terminal"] = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
          ["pwa-extensionHost"] = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
          ["codelldb"] = { "rust" },
          ["lldb"] = { "rust" },
          ["cppdbg"] = { "rust" },
          ["rust"] = { "rust" },
        }

        local function load_project_dap_file(target_bufnr)
          local bufnr = target_bufnr or vim.api.nvim_get_current_buf()
          local root = detect_debug_root(bufnr)
          if not root then
            return
          end

          local dap_file = root .. '/.nvim/dap.lua'
          if vim.fn.filereadable(dap_file) ~= 1 then
            return
          end

          _G._nixvim_dap_file_cache = _G._nixvim_dap_file_cache or {}
          local dap_file_cache = _G._nixvim_dap_file_cache
          local current_signature = build_cache_key(dap_file)
          if dap_file_cache[dap_file] == current_signature then
            return
          end

          local chunk, err = loadfile(dap_file)
          if not chunk then
            dprint('Failed to parse project dap.lua (' .. dap_file .. '): ' .. tostring(err))
            return
          end

          local ok, result = pcall(chunk)
          if not ok then
            dprint('Failed to load project dap.lua (' .. dap_file .. '): ' .. tostring(result))
            return
          end

          local project_loader = result
          if type(project_loader) == 'function' then
            local project_ok, project_err = pcall(project_loader, {
              dap = dap,
              root = root,
              bufnr = bufnr,
              filetype = vim.bo[bufnr].filetype,
            })
            if not project_ok then
              dprint('Failed to run project dap.lua (' .. dap_file .. '): ' .. tostring(project_err))
              return
            end
          end

          dap_file_cache[dap_file] = current_signature
        end

        local function load_project_launch_config(target_bufnr)
          local bufnr = target_bufnr or vim.api.nvim_get_current_buf()
          local root = detect_debug_root(bufnr)
          if not root then
            return
          end

          local launch_file = root .. '/.vscode/launch.json'
          if vim.fn.filereadable(launch_file) ~= 1 then
            return
          end

          _G._nixvim_launch_cache = _G._nixvim_launch_cache or {}
          local launch_cache = _G._nixvim_launch_cache
          local current_signature = build_cache_key(launch_file)
          if launch_cache[launch_file] == current_signature then
            return
          end

          local ok_ext, dap_ext = pcall(require, 'dap.ext.vscode')
          if not ok_ext then
            dprint('DAP launch loader unavailable: ' .. tostring(dap_ext))
            return
          end

          local ok, err = pcall(function()
            dap_ext.load_launchjs(launch_file, launch_type_map)
          end)
          if not ok then
            dprint('Failed to load launch.json (' .. launch_file .. '): ' .. tostring(err))
            return
          end

          launch_cache[launch_file] = current_signature
        end

        local function load_project_debug_config(bufnr)
          load_project_dap_file(bufnr)
          load_project_launch_config(bufnr)
        end

        local function detect_language_for_filetype(filetype)
          local language_map = {
            python = 'python',
            go = 'go',
            rust = 'rust',
            javascript = 'javascript',
            javascriptreact = 'javascript',
            typescript = 'typescript',
            typescriptreact = 'typescript',
          }

      local resolved = language_map[filetype] or filetype
      if type(resolved) ~= 'string' or resolved == "" then
        return 'python'
      end

      local supported_languages = {
        python = true,
        go = true,
        rust = true,
        javascript = true,
        typescript = true,
      }

      if supported_languages[resolved] then
        return resolved
      end

      return 'python'
    end

        local function dap_lua_template(language)
          local templates = {
            python = [=[return function(ctx)
      local dap = ctx.dap
      local root = ctx.root

      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "Project entrypoint",
          program = root .. "/main.py",
          cwd = root,
          console = "integratedTerminal",
          justMyCode = false,
        },
      }
    end
    ]=],
            go = [=[return function(ctx)
      local dap = ctx.dap
      local root = ctx.root

      dap.configurations.go = {
        {
          type = "go",
          request = "launch",
          name = "Project package",
          program = root,
          cwd = root,
        },
      }
    end
    ]=],
            rust = [=[return function(ctx)
      local dap = ctx.dap
      local root = ctx.root

      dap.configurations.rust = {
        {
          type = "codelldb",
          request = "launch",
          name = "Project binary",
          program = root .. "/target/debug/your-binary",
          cwd = root,
          stopOnEntry = false,
        },
      }
    end
    ]=],
            javascript = [=[return function(ctx)
      local dap = ctx.dap
      local root = ctx.root

      local configurations = {
        {
          type = "pwa-node",
          request = "launch",
          name = "Node current file",
      program = "''${file}",
          cwd = root,
          sourceMaps = true,
        },
      }

      dap.configurations.javascript = configurations
      dap.configurations.javascriptreact = configurations
    end
    ]=],
            typescript = [=[return function(ctx)
      local dap = ctx.dap
      local root = ctx.root

      local configurations = {
        {
          type = "pwa-node",
          request = "launch",
          name = "TypeScript current file",
      program = "''${file}",
          cwd = root,
          sourceMaps = true,
        },
      }

      dap.configurations.typescript = configurations
      dap.configurations.typescriptreact = configurations
    end
    ]=],
          }

          return templates[language] or templates.python
        end

        local function launch_json_template(language)
          local templates = {
            python = [=[{
      "version": "0.2.0",
      "configurations": [
        {
          "name": "Python: Current file",
          "type": "python",
          "request": "launch",
      "program": "''${file}",
      "cwd": "''${workspaceFolder}",
          "console": "integratedTerminal",
          "justMyCode": false
        }
      ]
    }
    ]=],
            go = [=[{
      "version": "0.2.0",
      "configurations": [
        {
          "name": "Go: Debug package",
          "type": "go",
          "request": "launch",
      "program": "''${workspaceFolder}",
      "cwd": "''${workspaceFolder}"
        }
      ]
    }
    ]=],
            rust = [=[{
      "version": "0.2.0",
      "configurations": [
        {
          "name": "Rust: Launch binary",
          "type": "codelldb",
          "request": "launch",
      "program": "''${workspaceFolder}/target/debug/your-binary",
      "cwd": "''${workspaceFolder}",
          "stopOnEntry": false
        }
      ]
    }
    ]=],
            javascript = [=[{
      "version": "0.2.0",
      "configurations": [
        {
          "name": "Node: Current file",
          "type": "pwa-node",
          "request": "launch",
      "program": "''${file}",
      "cwd": "''${workspaceFolder}",
          "sourceMaps": true
        }
      ]
    }
    ]=],
            typescript = [=[{
      "version": "0.2.0",
      "configurations": [
        {
          "name": "TypeScript: Current file",
          "type": "pwa-node",
          "request": "launch",
      "program": "''${file}",
      "cwd": "''${workspaceFolder}",
          "sourceMaps": true
        }
      ]
    }
    ]=],
          }

          return templates[language] or templates.python
        end

        local function write_project_debug_config(config_type, language)
          local bufnr = vim.api.nvim_get_current_buf()
          local root = detect_debug_root(bufnr) or vim.uv.cwd()
          local relative_path = config_type == 'dap.lua' and '.nvim/dap.lua' or '.vscode/launch.json'
          local full_path = root .. '/' .. relative_path
          local parent = vim.fs.dirname(full_path)

          vim.fn.mkdir(parent, 'p')

          if vim.fn.filereadable(full_path) ~= 1 then
            local lines = vim.split(
              config_type == 'dap.lua' and dap_lua_template(language) or launch_json_template(language),
              '\n',
              { plain = true }
            )
            vim.fn.writefile(lines, full_path)
          end

          vim.cmd('edit ' .. vim.fn.fnameescape(full_path))
          vim.notify('Opened ' .. relative_path .. ' for ' .. language .. ' debug configuration', vim.log.levels.INFO)
        end

        local function create_project_debug_config()
          local current_language = detect_language_for_filetype(vim.bo.filetype)
          local language_choices = { current_language }
          for _, language in ipairs({ 'python', 'go', 'rust', 'javascript', 'typescript' }) do
            if language ~= current_language then
              table.insert(language_choices, language)
            end
          end

          vim.ui.select({ 'dap.lua', 'launch.json' }, {
            prompt = 'Select project debug config type',
            format_item = function(item)
              return item == 'dap.lua' and '.nvim/dap.lua' or '.vscode/launch.json'
            end,
          }, function(config_type)
            if not config_type then
              return
            end

            vim.ui.select(language_choices, {
              prompt = 'Select debug language',
              format_item = function(item)
                if item == current_language then
                  return item .. ' (current file)'
                end
                return item
              end,
            }, function(language)
              if not language then
                return
              end

              write_project_debug_config(config_type, language)
            end)
          end)
        end

        local function show_debug_guidance()
          local bufnr = vim.api.nvim_get_current_buf()
          local filetype = vim.bo[bufnr].filetype
          local root = detect_debug_root(bufnr)
          local guidance = _G.debug_guidance_registry[filetype]

          if not guidance and root then
            if vim.uv.fs_stat(root .. '/pyproject.toml') or vim.uv.fs_stat(root .. '/setup.py') then
              guidance = _G.debug_guidance_registry.python
            elseif vim.uv.fs_stat(root .. '/Cargo.toml') then
              guidance = _G.debug_guidance_registry.rust
            elseif vim.uv.fs_stat(root .. '/go.mod') then
              guidance = _G.debug_guidance_registry.go
            elseif vim.uv.fs_stat(root .. '/package.json') or vim.uv.fs_stat(root .. '/tsconfig.json') then
              guidance = _G.debug_guidance_registry.typescript or _G.debug_guidance_registry.javascript
            end
          end

          if not guidance then
            guidance = table.concat({
              'No debug guidance is registered for `' .. (filetype ~= "" and filetype or 'this buffer') .. '`.',
              "",
              'Use <leader>dc once a DAP adapter/configuration has been added for this project.',
              'Project-local overrides can live in .nvim/dap.lua or .vscode/launch.json.',
            }, '\n')
          end

          local lines = vim.split(guidance, '\n', { plain = true })
          if root then
            table.insert(lines, 1, 'Project root: ' .. root)
            table.insert(lines, 2, "")
          end

          local buf = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
          vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
          vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
          vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

          local width = math.min(90, math.floor(vim.o.columns * 0.75))
          local height = math.min(#lines, math.floor(vim.o.lines * 0.6))
          local row = math.floor((vim.o.lines - height) / 2 - 1)
          local col = math.floor((vim.o.columns - width) / 2)

          local win = vim.api.nvim_open_win(buf, true, {
            relative = 'editor',
            row = math.max(row, 1),
            col = math.max(col, 0),
            width = width,
            height = math.max(height, 3),
            style = 'minimal',
            border = 'rounded',
            title = ' Debug guidance ',
            title_pos = 'center',
          })

          vim.keymap.set('n', 'q', function()
            vim.api.nvim_win_close(win, true)
          end, { buffer = buf, silent = true, desc = 'Close debug guidance' })
        end

        vim.api.nvim_create_user_command('DapLoadProjectConfig', function()
          load_project_debug_config(vim.api.nvim_get_current_buf())
        end, { desc = 'Reload project DAP config files' })

        vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
          callback = function(args)
            local buftype = vim.api.nvim_get_option_value('buftype', { buf = args.buf })
            if buftype ~= "" then
              return
            end
            load_project_debug_config(args.buf)
          end,
          desc = 'Load project DAP config on buffer open',
        })

        keymapd('<leader>dc', 'Debug: Continue', function()
          load_project_debug_config(vim.api.nvim_get_current_buf())
          dap.continue()
        end)
        keymapd('<leader>db', 'Debug: Toggle breakpoint', function()
          dap.toggle_breakpoint()
        end)
        keymapd('<leader>do', 'Debug: Step over', function()
          dap.step_over()
        end)
        keymapd('<leader>di', 'Debug: Step into', function()
          dap.step_into()
        end)
        keymapd('<leader>dO', 'Debug: Step out', function()
          dap.step_out()
        end)
        keymapd('<leader>du', 'Debug: Toggle UI', function()
          dapui.toggle()
        end)
        keymapd('<leader>dx', 'Debug: Terminate/disconnect', function()
          if dap.session() then
            dap.terminate()
          end
          dapui.close()
        end)
        keymapd('<leader>dg', 'Debug: Show guidance', show_debug_guidance)
        keymapd('<leader>dC', 'Debug: Create project config', create_project_debug_config)
  '';
in
{
  inherit name;

  inherit lua;

  vimPackages = with pkgs.vimPlugins; [
    nvim-dap
    nvim-dap-ui
    # Required by nvim-dap-ui
    nvim-nio
  ];
}
