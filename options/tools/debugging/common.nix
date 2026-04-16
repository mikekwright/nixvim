{ ... }:

let
  name = "tools.debugging";

  lua = /* lua */ ''
    _G.nixvim_debugger = _G.nixvim_debugger or {}
    _G.nixvim_debugging = _G.nixvim_debugger

    local dbg = _G.nixvim_debugger
    local helpers = _G.nixvim_helpers

    dbg.state = dbg.state or {}
    dbg.common = dbg.common or {}
    dbg.helpers = dbg.helpers or {}
    dbg.dap = dbg.dap or {}
    dbg.project_dap = dbg.project_dap or {}
    dbg.vscode = dbg.vscode or {}
    dbg.breakpoints = dbg.breakpoints or {}

    local function merge_into(target, source)
      if type(target) ~= 'table' or type(source) ~= 'table' then
        return target
      end

      for key, value in pairs(source) do
        if target[key] == nil then
          target[key] = value
        end
      end

      return target
    end

    dbg.state.language_registry = dbg.state.language_registry or _G.debug_language_registry or {}
    dbg.state.filetype_registry = dbg.state.filetype_registry or _G.debug_filetype_registry or {}
    merge_into(dbg.state.language_registry, _G.debug_language_registry)
    merge_into(dbg.state.filetype_registry, _G.debug_filetype_registry)

    dbg.state.project_registry = dbg.state.project_registry or {}
    dbg.state.breakpoint_cache = dbg.state.breakpoint_cache or {}
    dbg.state.session_task_registry = dbg.state.session_task_registry or setmetatable({}, { __mode = 'k' })
    dbg.state.active_task_runs = dbg.state.active_task_runs or {}
    dbg.state.recent_task_runs = dbg.state.recent_task_runs or {}
    dbg.state.last_task_status = dbg.state.last_task_status or nil
    dbg.state.last_completed_task_run = dbg.state.last_completed_task_run or nil
    dbg.state.next_task_run_id = dbg.state.next_task_run_id or 0
    dbg.state.task_output = dbg.state.task_output or {
      buf = nil,
      win = nil,
      mode = 'split',
    }
    dbg.state.task_defaults = dbg.state.task_defaults or {
      timeout_ms = 300000,
      statusline_ttl_ms = 10000,
      recent_runs_limit = 20,
    }
    dbg.state.profiles = dbg.state.profiles or {
      tasks = {},
      launch = {},
    }

    dbg.common.defaults = dbg.common.defaults or {
      tasks = {
        type = 'shell',
        problemMatcher = {},
        options = {
          cwd = '$' .. '{workspaceFolder}',
        },
        nixvim = {
          output = 'split',
        },
      },
      launch = {
        request = 'launch',
        cwd = '$' .. '{workspaceFolder}',
      },
    }

    _G.debug_language_registry = dbg.state.language_registry
    _G.debug_filetype_registry = dbg.state.filetype_registry

    _G.register_debug_language = function(spec)
      if type(spec) ~= 'table' or type(spec.id) ~= 'string' then
        return
      end

      dbg.state.language_registry[spec.id] = spec

      for _, filetype in ipairs(spec.filetypes or {}) do
        dbg.state.filetype_registry[filetype] = spec.id
      end
    end

    dbg.helpers.build_cache_key = helpers.build_cache_key
    dbg.helpers.find_project_root_from_marker_path = helpers.find_project_root_from_marker_path
    dbg.helpers.find_nearest_navigating_up = helpers.find_nearest_navigating_up

    dbg.helpers.normalize_task_profile = function(profile)
      local normalized = vim.tbl_deep_extend('force', vim.deepcopy(dbg.common.defaults.tasks), vim.deepcopy(profile or {}))
      local id = type(normalized.id) == 'string' and normalized.id or nil
      local label = type(normalized.label) == 'string' and normalized.label or nil

      if not label or label == "" then
        normalized.label = id or normalized.name
      end

      return normalized
    end

    dbg.helpers.normalize_launch_profile = function(profile)
      local normalized = vim.tbl_deep_extend('force', vim.deepcopy(dbg.common.defaults.launch), vim.deepcopy(profile or {}))
      local id = type(normalized.id) == 'string' and normalized.id or nil
      local name = type(normalized.name) == 'string' and normalized.name or nil

      if not name or name == "" then
        normalized.name = id or normalized.label
      end

      return normalized
    end

    dbg.helpers.register_task_profile = function(id, profile)
      if type(id) ~= 'string' or id == "" then
        return
      end

      dbg.state.profiles.tasks[id] = dbg.helpers.normalize_task_profile(vim.tbl_extend('keep', profile or {}, { id = id }))
    end

    dbg.helpers.register_launch_profile = function(id, profile)
      if type(id) ~= 'string' or id == "" then
        return
      end

      dbg.state.profiles.launch[id] = dbg.helpers.normalize_launch_profile(vim.tbl_extend('keep', profile or {}, { id = id }))
    end

    dbg.helpers.get_task_profile = function(id)
      return type(id) == 'string' and dbg.state.profiles.tasks[id] or nil
    end

    dbg.helpers.get_launch_profile = function(id)
      return type(id) == 'string' and dbg.state.profiles.launch[id] or nil
    end

    dbg.helpers.get_root_markers = function(extra_markers)
      local markers = { '.git' }
      local seen = { ['.git'] = true }

      for _, marker in ipairs(extra_markers or {}) do
        if not seen[marker] then
          table.insert(markers, marker)
          seen[marker] = true
        end
      end

      for _, spec in pairs(dbg.state.language_registry) do
        for _, marker in ipairs(spec.root_markers or {}) do
          if not seen[marker] then
            table.insert(markers, marker)
            seen[marker] = true
          end
        end
      end

      return markers
    end

    dbg.helpers.detect_project_root = function(bufnr, extra_markers)
      return helpers.detect_project_root(bufnr, dbg.helpers.get_root_markers(extra_markers))
    end

    dbg.helpers.get_registered_language_ids = function()
      local ids = {}
      for language, _ in pairs(dbg.state.language_registry) do
        table.insert(ids, language)
      end
      table.sort(ids)
      return ids
    end

    dbg.helpers.get_debug_language = function(language)
      return language and dbg.state.language_registry[language] or nil
    end

    dbg.helpers.get_debug_language_for_filetype = function(filetype)
      return dbg.helpers.get_debug_language(dbg.state.filetype_registry[filetype])
    end

    dbg.helpers.get_debug_language_for_root = function(root)
      if not root then
        return nil
      end

      for _, language in ipairs(dbg.helpers.get_registered_language_ids()) do
        local spec = dbg.helpers.get_debug_language(language)
        for _, marker in ipairs(spec.root_markers or {}) do
          if vim.uv.fs_stat(root .. '/' .. marker) then
            return spec
          end
        end
      end
    end

    dbg.helpers.refresh_statusline = function()
      local ok, lualine = pcall(require, 'lualine')
      if ok and lualine.refresh then
        lualine.refresh({ place = { 'statusline' }, trigger = 'nixvim_debugging' })
      end
    end

    dbg.helpers.set_task_status = function(message, level)
      dbg.state.last_task_status = {
        message = message,
        level = level or vim.log.levels.INFO,
        updated_at = vim.uv.now(),
      }
      dbg.helpers.refresh_statusline()
    end

    dbg.helpers.ensure_task_output_buffer = function()
      local output = dbg.state.task_output
      if output.buf and vim.api.nvim_buf_is_valid(output.buf) then
        return output.buf
      end

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
      vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = buf })
      vim.api.nvim_set_option_value('swapfile', false, { buf = buf })
      vim.api.nvim_set_option_value('filetype', 'log', { buf = buf })
      output.buf = buf
      return buf
    end

    dbg.helpers.open_task_output_window = function(mode)
      local output = dbg.state.task_output
      local buf = dbg.helpers.ensure_task_output_buffer()
      local target_mode = mode or output.mode or 'split'
      output.mode = target_mode

      if output.win and vim.api.nvim_win_is_valid(output.win) then
        vim.api.nvim_set_current_win(output.win)
        return output.win
      end

      if target_mode == 'float' then
        local width = math.min(120, math.max(80, math.floor(vim.o.columns * 0.8)))
        local height = math.min(20, math.max(8, math.floor(vim.o.lines * 0.3)))
        output.win = vim.api.nvim_open_win(buf, false, {
          relative = 'editor',
          row = math.max(1, vim.o.lines - height - 4),
          col = math.max(0, math.floor((vim.o.columns - width) / 2)),
          width = width,
          height = height,
          style = 'minimal',
          border = 'rounded',
          title = ' Debug task output ',
          title_pos = 'center',
        })
      else
        vim.cmd('botright 10split')
        output.win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(output.win, buf)
        vim.api.nvim_set_option_value('winfixheight', true, { win = output.win })
      end

      vim.api.nvim_set_option_value('wrap', false, { win = output.win })
      return output.win
    end

    dbg.helpers.show_task_output = function(run_or_mode, maybe_mode)
      local mode = maybe_mode or (type(run_or_mode) == 'string' and run_or_mode or nil)
      dbg.helpers.open_task_output_window(mode)
    end

    dbg.helpers.reset_task_output = function(run_or_title, maybe_title)
      local title = maybe_title or (type(run_or_title) == 'string' and run_or_title or nil)
      local buf = dbg.helpers.ensure_task_output_buffer()
      vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, title and { title, "" } or {})
      vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
      dbg.helpers.show_task_output()
    end

    dbg.helpers.append_task_output = function(run_or_stream, maybe_stream, maybe_chunk)
      local stream = maybe_chunk ~= nil and maybe_stream or run_or_stream
      local chunk = maybe_chunk ~= nil and maybe_chunk or maybe_stream
      if type(chunk) ~= 'string' or chunk == "" then
        return
      end

      local buf = dbg.helpers.ensure_task_output_buffer()
      local prefix = stream == 'stderr' and '[stderr] ' or ""
      local lines = vim.split(chunk, '\n', { plain = true })
      if #lines > 0 and lines[#lines] == "" then
        table.remove(lines, #lines)
      end
      if #lines == 0 then
        return
      end

      for index, line in ipairs(lines) do
        lines[index] = prefix .. line
      end

      vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
      local start_line = vim.api.nvim_buf_line_count(buf)
      vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
      vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

      if stream == 'stderr' then
        for offset = 0, #lines - 1 do
          pcall(vim.api.nvim_buf_add_highlight, buf, -1, 'DiagnosticError', start_line + offset, 0, -1)
        end
      end

      local output = dbg.state.task_output
      if output.win and vim.api.nvim_win_is_valid(output.win) then
        vim.api.nvim_win_set_cursor(output.win, { vim.api.nvim_buf_line_count(buf), 0 })
      end
    end

    dbg.helpers.start_task_run = function(task)
      dbg.state.next_task_run_id = dbg.state.next_task_run_id + 1
      local id = dbg.state.next_task_run_id
      dbg.state.active_task_runs[id] = vim.tbl_extend('force', {
        id = id,
        status = 'running',
        started_at = vim.uv.now(),
        handle = nil,
        timer = nil,
        stdout = nil,
        stderr = nil,
        canceled = false,
        timed_out = false,
      }, task or {})
      dbg.helpers.refresh_statusline()
      return id
    end

    dbg.helpers.finish_task_run = function(id, status, message, level)
      local run = dbg.state.active_task_runs[id]
      if run then
        run.status = status or 'completed'
        run.message = message or run.message
        run.completed_at = vim.uv.now()
        if run.timer then
          pcall(run.timer.stop, run.timer)
          pcall(run.timer.close, run.timer)
          run.timer = nil
        end
        run.handle = nil
        run.stdout = nil
        run.stderr = nil
        dbg.state.last_completed_task_run = vim.deepcopy(run)
        table.insert(dbg.state.recent_task_runs, 1, vim.deepcopy(run))
        while #dbg.state.recent_task_runs > dbg.state.task_defaults.recent_runs_limit do
          table.remove(dbg.state.recent_task_runs)
        end
        dbg.state.active_task_runs[id] = nil
      end
      if message then
        dbg.helpers.set_task_status(message, level)
      else
        dbg.helpers.refresh_statusline()
      end
    end

    dbg.helpers.get_active_task_run = function(id)
      return dbg.state.active_task_runs[id]
    end

    dbg.helpers.start_task_timeout = function(id, timeout_ms, on_timeout)
      local run = dbg.helpers.get_active_task_run(id)
      if not run or not timeout_ms or timeout_ms <= 0 then
        return
      end

      local timer = vim.uv.new_timer()
      run.timer = timer
      timer:start(timeout_ms, 0, function()
        vim.schedule(function()
          local current = dbg.helpers.get_active_task_run(id)
          if not current then
            return
          end
          current.timed_out = true
          if on_timeout then
            on_timeout(current)
          end
        end)
      end)
    end

    dbg.helpers.cancel_task_run = function(id, reason)
      local run = dbg.helpers.get_active_task_run(id)
      if not run or not run.handle then
        return false
      end

      run.canceled = true
      run.cancel_reason = reason or 'Canceled'
      pcall(run.handle.kill, run.handle, 'sigterm')
      vim.defer_fn(function()
        local current = dbg.helpers.get_active_task_run(id)
        if current and current.handle then
          pcall(current.handle.kill, current.handle, 'sigkill')
        end
      end, 1500)
      return true
    end

    dbg.helpers.cancel_all_task_runs = function(reason)
      local canceled = false
      for id, _ in pairs(dbg.state.active_task_runs) do
        canceled = dbg.helpers.cancel_task_run(id, reason) or canceled
      end
      return canceled
    end

    dbg.helpers.get_running_debug_tasks = function()
      local tasks = {}
      for _, run in pairs(dbg.state.active_task_runs) do
        if run.status == 'running' then
          table.insert(tasks, run)
        end
      end
      table.sort(tasks, function(left, right)
        return left.started_at < right.started_at
      end)
      return tasks
    end

    dbg.helpers.get_recent_task_runs = function()
      local runs = {}
      for _, run in ipairs(dbg.state.recent_task_runs) do
        table.insert(runs, vim.deepcopy(run))
      end
      return runs
    end

    dbg.helpers.describe_task_run = function(run)
      local phase = run.phase == 'preLaunchTask' and 'pre' or (run.phase == 'postDebugTask' and 'post' or (run.phase or 'task'))
      return string.format('%s: %s [%s]', phase, run.label or 'task', run.status or 'unknown')
    end

    dbg.helpers.pick_recent_task_run = function()
      local items = {}

      for _, run in ipairs(dbg.helpers.get_running_debug_tasks()) do
        table.insert(items, {
          text = dbg.helpers.describe_task_run(run),
          run = run,
        })
      end

      for _, run in ipairs(dbg.helpers.get_recent_task_runs()) do
        table.insert(items, {
          text = dbg.helpers.describe_task_run(run),
          run = run,
        })
      end

      if #items == 0 then
        vim.notify('No recent debug task runs found', vim.log.levels.INFO)
        return
      end

      local function show_item(item)
        if not item or not item.run then
          return
        end

        dbg.helpers.show_task_output()
        vim.notify(item.run.message or item.text, vim.log.levels.INFO)
      end

      vim.ui.select(items, {
        prompt = 'Debug task runs',
        format_item = function(item)
          return item.text
        end,
      }, show_item)
    end

    dbg.helpers.debug_task_statusline = function()
      local tasks = dbg.helpers.get_running_debug_tasks()
      if #tasks == 0 then
        local last_run = dbg.state.last_completed_task_run
        local ttl_ms = dbg.state.task_defaults.statusline_ttl_ms
        if not last_run or not last_run.completed_at or (vim.uv.now() - last_run.completed_at) > ttl_ms then
          return ""
        end

        local icons = {
          completed = '',
          failed = '',
          canceled = '󰜺',
          timeout = '󰔛',
        }
        return (icons[last_run.status] or '') .. ' ' .. ((last_run.phase == 'preLaunchTask') and 'pre' or 'post') .. ': ' .. (last_run.label or 'task')
      end
      if #tasks == 1 then
        local run = tasks[1]
        local phase = run.phase == 'preLaunchTask' and 'pre' or 'post'
        return '󱐋 ' .. phase .. ': ' .. (run.label or 'task')
      end
      return '󱐋 ' .. tostring(#tasks) .. ' debug tasks'
    end

    dbg.helpers.debug_task_statusline_color = function()
      local tasks = dbg.helpers.get_running_debug_tasks()
      if #tasks > 0 then
        return { fg = '#61afef' }
      end

      local last_run = dbg.state.last_completed_task_run
      local ttl_ms = dbg.state.task_defaults.statusline_ttl_ms
      if not last_run or not last_run.completed_at or (vim.uv.now() - last_run.completed_at) > ttl_ms then
        return nil
      end

      local colors = {
        completed = '#98c379',
        failed = '#e86671',
        canceled = '#e5c07b',
        timeout = '#d19a66',
      }
      return { fg = colors[last_run.status] or '#98c379' }
    end
  '';
in
{
  inherit lua name;
}
