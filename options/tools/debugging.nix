{ pkgs, ... }:

let
  name = "tools.debugging";

  lua = /* lua */ ''
    _G.debug_language_registry = _G.debug_language_registry or {}
    _G.debug_filetype_registry = _G.debug_filetype_registry or {}

    _G.register_debug_language = _G.register_debug_language or function(spec)
      if type(spec) ~= 'table' or type(spec.id) ~= 'string' then
        return
      end

      _G.debug_language_registry[spec.id] = spec

      for _, filetype in ipairs(spec.filetypes or {}) do
        _G.debug_filetype_registry[filetype] = spec.id
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

    local function get_root_markers()
      local markers = { '.git' }
      local seen = { ['.git'] = true }

      for _, spec in pairs(_G.debug_language_registry) do
        for _, marker in ipairs(spec.root_markers or {}) do
          if not seen[marker] then
            table.insert(markers, marker)
            seen[marker] = true
          end
        end
      end

      return markers
    end

    local function detect_debug_root(bufnr)
      local buffer_name = vim.api.nvim_buf_get_name(bufnr)
      local start_path = buffer_name ~= "" and vim.fs.dirname(buffer_name) or vim.uv.cwd()

      local root = vim.fs.find(get_root_markers(), {
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

    local function get_registered_language_ids()
      local ids = {}
      for language, _ in pairs(_G.debug_language_registry) do
        table.insert(ids, language)
      end
      table.sort(ids)
      return ids
    end

    local function get_debug_language(language)
      return language and _G.debug_language_registry[language] or nil
    end

    local function get_debug_language_for_filetype(filetype)
      return get_debug_language(_G.debug_filetype_registry[filetype])
    end

    local function get_debug_language_for_root(root)
      if not root then
        return nil
      end

      for _, language in ipairs(get_registered_language_ids()) do
        local spec = get_debug_language(language)
        for _, marker in ipairs(spec.root_markers or {}) do
          if vim.uv.fs_stat(root .. '/' .. marker) then
            return spec
          end
        end
      end
    end

    local function build_launch_type_map()
      local launch_type_map = {}

      for _, language in ipairs(get_registered_language_ids()) do
        local spec = get_debug_language(language)
        for _, launch_type in ipairs(spec.launch_types or {}) do
          launch_type_map[launch_type] = launch_type_map[launch_type] or {}
          local seen = {}
          for _, filetype in ipairs(launch_type_map[launch_type]) do
            seen[filetype] = true
          end
          for _, filetype in ipairs(spec.filetypes or {}) do
            if not seen[filetype] then
              table.insert(launch_type_map[launch_type], filetype)
              seen[filetype] = true
            end
          end
        end
      end

      return launch_type_map
    end

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

      if type(result) == 'function' then
        local project_ok, project_err = pcall(result, {
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
        dap_ext.load_launchjs(launch_file, build_launch_type_map())
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

    local function create_project_debug_config()
      local current_spec = get_debug_language_for_filetype(vim.bo.filetype)
      local language_choices = {}

      if current_spec then
        table.insert(language_choices, current_spec.id)
      end

      for _, language in ipairs(get_registered_language_ids()) do
        if not current_spec or language ~= current_spec.id then
          table.insert(language_choices, language)
        end
      end

      if #language_choices == 0 then
        vim.notify('No language-specific debug config generators are registered in this package', vim.log.levels.WARN)
        return
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
          format_item = function(language)
            local spec = get_debug_language(language)
            local label = spec and spec.label or language
            if current_spec and language == current_spec.id then
              return label .. ' (current file)'
            end
            return label
          end,
        }, function(language)
          if not language then
            return
          end

          local spec = get_debug_language(language)
          if not spec or type(spec.templates) ~= 'table' or type(spec.templates[config_type]) ~= 'string' then
            vim.notify('No ' .. config_type .. ' template is registered for ' .. language, vim.log.levels.WARN)
            return
          end

          local bufnr = vim.api.nvim_get_current_buf()
          local root = detect_debug_root(bufnr) or vim.uv.cwd()
          local relative_path = config_type == 'dap.lua' and '.nvim/dap.lua' or '.vscode/launch.json'
          local full_path = root .. '/' .. relative_path
          local parent = vim.fs.dirname(full_path)

          vim.fn.mkdir(parent, 'p')

          if vim.fn.filereadable(full_path) ~= 1 then
            vim.fn.writefile(vim.split(spec.templates[config_type], '\n', { plain = true }), full_path)
          end

          vim.cmd('edit ' .. vim.fn.fnameescape(full_path))
          vim.notify('Opened ' .. relative_path .. ' for ' .. (spec.label or language) .. ' debug configuration', vim.log.levels.INFO)
        end)
      end)
    end

    local function show_debug_guidance()
      local bufnr = vim.api.nvim_get_current_buf()
      local filetype = vim.bo[bufnr].filetype
      local root = detect_debug_root(bufnr)
      local spec = get_debug_language_for_filetype(filetype) or get_debug_language_for_root(root)

      local guidance = spec and spec.guidance or table.concat({
        'No debug guidance is registered for `' .. (filetype ~= "" and filetype or 'this buffer') .. '`.',
        "",
        'Use <leader>dc once a DAP adapter/configuration has been added for this project.',
        'Project-local overrides can live in .nvim/dap.lua or .vscode/launch.json.',
      }, '\n')

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
  inherit name lua;

  vimPackages = with pkgs.vimPlugins; [
    nvim-dap
    nvim-dap-ui
    nvim-nio
  ];
}
