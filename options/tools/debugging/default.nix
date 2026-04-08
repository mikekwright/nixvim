{ pkgs, ... }:

let
  name = "tools.debugging";

  lua = /* lua */ ''
    _G.nixvim_debugging = _G.nixvim_debugging or {}

    _G.nixvim_debugging.state = _G.nixvim_debugging.state or {
      language_registry = {},
      filetype_registry = {},
      project_registry = {},
      breakpoint_cache = {},
      breakpoint_wrapped = false,
      session_task_registry = setmetatable({}, { __mode = 'k' }),
      active_task_runs = {},
      last_task_status = nil,
      last_completed_task_run = nil,
      next_task_run_id = 0,
      task_output = {
        win = nil,
        mode = 'split',
        current_run_id = nil,
      },
      task_defaults = {
        timeout_ms = 300000,
        statusline_ttl_ms = 10000,
        recent_task_runs_limit = 20,
      },
      recent_task_runs = {},
    }

    _G.nixvim_debugging.helpers = _G.nixvim_debugging.helpers or {}
    _G.nixvim_debugging.dap = _G.nixvim_debugging.dap or {}
    _G.nixvim_debugging.vscode = _G.nixvim_debugging.vscode or {}
    _G.nixvim_debugging.breakpoints = _G.nixvim_debugging.breakpoints or {}

    _G.debug_language_registry = _G.nixvim_debugging.state.language_registry
    _G.debug_filetype_registry = _G.nixvim_debugging.state.filetype_registry

    _G.register_debug_language = function(spec)
      if type(spec) ~= 'table' or type(spec.id) ~= 'string' then
        return
      end

      _G.nixvim_debugging.state.language_registry[spec.id] = spec

      for _, filetype in ipairs(spec.filetypes or {}) do
        _G.nixvim_debugging.state.filetype_registry[filetype] = spec.id
      end
    end

    _G.nixvim_debugging.helpers.build_cache_key = function(path)
      local stat = vim.uv.fs_stat(path)
      if not stat or not stat.mtime then
        return nil
      end

      return tostring(stat.mtime.sec) .. ':' .. tostring(stat.mtime.nsec or 0)
    end

    _G.nixvim_debugging.helpers.project_root_from_marker = function(path)
      local normalized = vim.fs.normalize(path)
      if normalized:match('/%.nvim/dap%.lua$')
        or normalized:match('/%.vscode/launch%.json$')
        or normalized:match('/%.vscode/tasks%.json$')
        or normalized:match('/%.nvim/dap%-breakpoints%.json$') then
        return vim.fs.dirname(vim.fs.dirname(normalized))
      end

      return vim.fs.dirname(normalized)
    end

    _G.nixvim_debugging.helpers.find_upward = function(bufnr, marker)
      local buffer_name = vim.api.nvim_buf_get_name(bufnr)
      local start_path = buffer_name ~= "" and vim.fs.dirname(buffer_name) or vim.uv.cwd()

      return vim.fs.find(marker, {
        path = start_path,
        upward = true,
        stop = vim.uv.os_homedir(),
      })[1]
    end

    _G.nixvim_debugging.helpers.get_root_markers = function(extra_markers)
      local markers = { '.git' }
      local seen = { ['.git'] = true }

      for _, marker in ipairs(extra_markers or {}) do
        if not seen[marker] then
          table.insert(markers, marker)
          seen[marker] = true
        end
      end

      for _, spec in pairs(_G.nixvim_debugging.state.language_registry) do
        for _, marker in ipairs(spec.root_markers or {}) do
          if not seen[marker] then
            table.insert(markers, marker)
            seen[marker] = true
          end
        end
      end

      return markers
    end

    _G.nixvim_debugging.helpers.detect_root = function(bufnr, extra_markers)
      local buffer_name = vim.api.nvim_buf_get_name(bufnr)
      local start_path = buffer_name ~= "" and vim.fs.dirname(buffer_name) or vim.uv.cwd()
      local marker = vim.fs.find(_G.nixvim_debugging.helpers.get_root_markers(extra_markers), {
        path = start_path,
        upward = true,
        stop = vim.uv.os_homedir(),
      })[1]

      if not marker then
        return nil
      end

      return _G.nixvim_debugging.helpers.project_root_from_marker(marker)
    end

    _G.nixvim_debugging.helpers.get_registered_language_ids = function()
      local ids = {}
      for language, _ in pairs(_G.nixvim_debugging.state.language_registry) do
        table.insert(ids, language)
      end
      table.sort(ids)
      return ids
    end

    _G.nixvim_debugging.helpers.get_debug_language = function(language)
      return language and _G.nixvim_debugging.state.language_registry[language] or nil
    end

    _G.nixvim_debugging.helpers.get_debug_language_for_filetype = function(filetype)
      return _G.nixvim_debugging.helpers.get_debug_language(_G.nixvim_debugging.state.filetype_registry[filetype])
    end

    _G.nixvim_debugging.helpers.get_debug_language_for_root = function(root)
      if not root then
        return nil
      end

      for _, language in ipairs(_G.nixvim_debugging.helpers.get_registered_language_ids()) do
        local spec = _G.nixvim_debugging.helpers.get_debug_language(language)
        for _, marker in ipairs(spec.root_markers or {}) do
          if vim.uv.fs_stat(root .. '/' .. marker) then
            return spec
          end
        end
      end
    end

    _G.nixvim_debugging.helpers.refresh_statusline = function()
      local ok, lualine = pcall(require, 'lualine')
      if ok and lualine.refresh then
        lualine.refresh({ place = { 'statusline' }, trigger = 'nixvim_debugging' })
      end
    end

    _G.nixvim_debugging.helpers.set_task_status = function(message, level)
      _G.nixvim_debugging.state.last_task_status = {
        message = message,
        level = level or vim.log.levels.INFO,
        updated_at = vim.uv.now(),
      }
      _G.nixvim_debugging.helpers.refresh_statusline()
    end

    _G.nixvim_debugging.helpers.ensure_task_output_buffer = function(run_id)
      local run = run_id and _G.nixvim_debugging.state.active_task_runs[run_id]
      if not run and run_id then
        for _, item in ipairs(_G.nixvim_debugging.state.recent_task_runs) do
          if item.id == run_id then
            run = item
            break
          end
        end
      end

      if run and run.output_buf and vim.api.nvim_buf_is_valid(run.output_buf) then
        return run.output_buf
      end

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
      vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = buf })
      vim.api.nvim_set_option_value('swapfile', false, { buf = buf })
      vim.api.nvim_set_option_value('filetype', 'log', { buf = buf })
      if run then
        run.output_buf = buf
      end
      return buf
    end

    _G.nixvim_debugging.helpers.open_task_output_window = function(run_id, mode)
      local output = _G.nixvim_debugging.state.task_output
      local buf = _G.nixvim_debugging.helpers.ensure_task_output_buffer(run_id)
      local target_mode = mode or output.mode or 'split'
      output.mode = target_mode
      output.current_run_id = run_id or output.current_run_id

      if output.win and vim.api.nvim_win_is_valid(output.win) then
        vim.api.nvim_set_current_win(output.win)
        vim.api.nvim_win_set_buf(output.win, buf)
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

    _G.nixvim_debugging.helpers.show_task_output = function(run_id, mode)
      _G.nixvim_debugging.helpers.open_task_output_window(run_id or _G.nixvim_debugging.state.task_output.current_run_id, mode)
    end

    _G.nixvim_debugging.helpers.reset_task_output = function(run_id, title)
      local buf = _G.nixvim_debugging.helpers.ensure_task_output_buffer(run_id)
      vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, title and { title, "" } or {})
      vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
      _G.nixvim_debugging.helpers.show_task_output(run_id)
    end

    _G.nixvim_debugging.helpers.append_task_output = function(run_id, stream, chunk)
      if type(chunk) ~= 'string' or chunk == "" then
        return
      end

      local buf = _G.nixvim_debugging.helpers.ensure_task_output_buffer(run_id)
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

      local output = _G.nixvim_debugging.state.task_output
      if output.current_run_id == run_id and output.win and vim.api.nvim_win_is_valid(output.win) then
        vim.api.nvim_win_set_cursor(output.win, { vim.api.nvim_buf_line_count(buf), 0 })
      end
    end

    _G.nixvim_debugging.helpers.start_task_run = function(task)
      _G.nixvim_debugging.state.next_task_run_id = _G.nixvim_debugging.state.next_task_run_id + 1
      local id = _G.nixvim_debugging.state.next_task_run_id
      _G.nixvim_debugging.state.active_task_runs[id] = vim.tbl_extend('force', {
        id = id,
        status = 'running',
        started_at = vim.uv.now(),
        handle = nil,
        timer = nil,
        stdout = nil,
        stderr = nil,
        canceled = false,
        timed_out = false,
        output_buf = nil,
      }, task or {})
      _G.nixvim_debugging.helpers.refresh_statusline()
      return id
    end

    _G.nixvim_debugging.helpers.finish_task_run = function(id, status, message, level)
      local run = _G.nixvim_debugging.state.active_task_runs[id]
      if run then
        run.status = status or 'completed'
        run.message = message
        run.level = level
        run.completed_at = vim.uv.now()
        run.duration_ms = run.started_at and (run.completed_at - run.started_at) or nil
        if run.timer then
          pcall(run.timer.stop, run.timer)
          pcall(run.timer.close, run.timer)
          run.timer = nil
        end
        run.handle = nil
        run.stdout = nil
        run.stderr = nil
        table.insert(_G.nixvim_debugging.state.recent_task_runs, 1, vim.deepcopy(run))
        while #_G.nixvim_debugging.state.recent_task_runs > _G.nixvim_debugging.state.task_defaults.recent_task_runs_limit do
          table.remove(_G.nixvim_debugging.state.recent_task_runs)
        end
        _G.nixvim_debugging.state.last_completed_task_run = vim.deepcopy(run)
        _G.nixvim_debugging.state.active_task_runs[id] = nil
      end
      if message then
        _G.nixvim_debugging.helpers.set_task_status(message, level)
      else
        _G.nixvim_debugging.helpers.refresh_statusline()
      end
    end

    _G.nixvim_debugging.helpers.get_active_task_run = function(id)
      return _G.nixvim_debugging.state.active_task_runs[id]
    end

    _G.nixvim_debugging.helpers.start_task_timeout = function(id, timeout_ms, on_timeout)
      local run = _G.nixvim_debugging.helpers.get_active_task_run(id)
      if not run or not timeout_ms or timeout_ms <= 0 then
        return
      end

      local timer = vim.uv.new_timer()
      if not timer then
        return
      end
      run.timer = timer
      timer:start(timeout_ms, 0, function()
        vim.schedule(function()
          local current = _G.nixvim_debugging.helpers.get_active_task_run(id)
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

    _G.nixvim_debugging.helpers.cancel_task_run = function(id, reason)
      local run = _G.nixvim_debugging.helpers.get_active_task_run(id)
      if not run or not run.handle then
        return false
      end

      run.canceled = true
      run.cancel_reason = reason or 'Canceled'
      pcall(run.handle.kill, run.handle, 'SIGTERM')
      vim.defer_fn(function()
        local current = _G.nixvim_debugging.helpers.get_active_task_run(id)
        if current and current.handle then
          pcall(current.handle.kill, current.handle, 'SIGKILL')
        end
      end, 1500)
      return true
    end

    _G.nixvim_debugging.helpers.cancel_all_task_runs = function(reason)
      local canceled = false
      for id, _ in pairs(_G.nixvim_debugging.state.active_task_runs) do
        canceled = _G.nixvim_debugging.helpers.cancel_task_run(id, reason) or canceled
      end
      return canceled
    end

    _G.nixvim_debugging.helpers.get_running_debug_tasks = function()
      local tasks = {}
      for _, run in pairs(_G.nixvim_debugging.state.active_task_runs) do
        if run.status == 'running' then
          table.insert(tasks, run)
        end
      end
      table.sort(tasks, function(left, right)
        return left.started_at < right.started_at
      end)
      return tasks
    end

    _G.nixvim_debugging.helpers.get_recent_task_runs = function()
      return vim.deepcopy(_G.nixvim_debugging.state.recent_task_runs)
    end

    _G.nixvim_debugging.helpers.open_recent_task_run = function(item)
      if item and item.id then
        _G.nixvim_debugging.helpers.show_task_output(item.id)
      end
    end

    _G.nixvim_debugging.helpers.format_task_run_duration = function(duration_ms)
      if type(duration_ms) ~= 'number' then
        return 'n/a'
      end
      if duration_ms < 1000 then
        return tostring(duration_ms) .. 'ms'
      end
      if duration_ms < 60000 then
        return string.format('%.1fs', duration_ms / 1000)
      end
      return string.format('%.1fm', duration_ms / 60000)
    end

    _G.nixvim_debugging.helpers.format_task_run_timestamp = function(timestamp_ms)
      if type(timestamp_ms) ~= 'number' then
        return 'unknown'
      end
      return os.date('%Y-%m-%d %H:%M:%S', math.floor(timestamp_ms / 1000))
    end

    _G.nixvim_debugging.helpers.format_task_run_status = function(item)
      local labels = {
        completed = 'success',
        failed = 'failed',
        canceled = 'canceled',
        timeout = 'timeout',
      }
      return labels[item.status] or (item.status or 'unknown')
    end

    _G.nixvim_debugging.helpers.pick_recent_task_run = function()
      local items = _G.nixvim_debugging.helpers.get_recent_task_runs()
      if #items == 0 then
        vim.notify('No recent debug task runs found', vim.log.levels.INFO)
        return
      end

      for _, item in ipairs(items) do
        local phase = item.phase == 'preLaunchTask' and 'pre' or 'post'
        item.text = string.format(
          '%s %s: %s | %s | %s | %s',
          _G.nixvim_debugging.helpers.format_task_run_status(item),
          phase,
          item.label or 'task',
          _G.nixvim_debugging.helpers.format_task_run_duration(item.duration_ms),
          item.project_root or 'unknown project',
          _G.nixvim_debugging.helpers.format_task_run_timestamp(item.completed_at or item.started_at)
        )
      end

      local has_snacks, snacks = pcall(require, 'snacks')
      if has_snacks and snacks.picker then
        snacks.picker.pick({
          source = 'debug-task-runs',
          items = items,
          layout = 'vscode',
          format = 'text',
          title = 'Recent debug task runs',
          confirm = function(picker, item)
            picker:close()
            _G.nixvim_debugging.helpers.open_recent_task_run(item)
          end,
        })
        return
      end

      vim.ui.select(items, {
        prompt = 'Recent debug task runs',
        format_item = function(item)
          return item.text
        end,
      }, _G.nixvim_debugging.helpers.open_recent_task_run)
    end

    _G.nixvim_debugging.helpers.debug_task_statusline = function()
      local tasks = _G.nixvim_debugging.helpers.get_running_debug_tasks()
      if #tasks == 0 then
        local last_run = _G.nixvim_debugging.state.last_completed_task_run
        local ttl_ms = _G.nixvim_debugging.state.task_defaults.statusline_ttl_ms
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

    _G.nixvim_debugging.helpers.debug_task_statusline_color = function()
      local tasks = _G.nixvim_debugging.helpers.get_running_debug_tasks()
      if #tasks > 0 then
        return { fg = '#61afef' }
      end

      local last_run = _G.nixvim_debugging.state.last_completed_task_run
      local ttl_ms = _G.nixvim_debugging.state.task_defaults.statusline_ttl_ms
      if not last_run or not last_run.completed_at or (vim.uv.now() - last_run.completed_at) > ttl_ms then
        return {}
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
  inherit name lua;

  imports = [
    ./dap.nix
    ./vscode.nix
    ./breakpoints.nix
  ];

  vimPackages = with pkgs.vimPlugins; [
    nvim-dap
    nvim-dap-ui
    nvim-nio
  ];
}
