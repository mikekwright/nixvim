{ ... }:

let
  name = "tools.debugging";

  lua = /* lua */ ''
    local dbg = _G.nixvim_debugger
    local dap = require('dap')

    dbg.vscode.find_project_launch_file = function(bufnr)
      return dbg.helpers.find_nearest_navigating_up(bufnr, '.vscode/launch.json')
    end

    dbg.vscode.find_project_tasks_file = function(bufnr)
      return dbg.helpers.find_nearest_navigating_up(bufnr, '.vscode/tasks.json')
    end

    dbg.vscode.build_project_signature = function(paths)
      local parts = {}
      for _, path in ipairs(paths) do
        if path then
          table.insert(parts, path .. ':' .. (dbg.helpers.build_cache_key(path) or 'missing'))
        end
      end
      table.sort(parts)
      return table.concat(parts, '|')
    end

    dbg.vscode.build_launch_type_to_filetypes = function()
      local mapping = {}
      for _, spec in pairs(dbg.state.language_registry) do
        for _, launch_type in ipairs(spec.launch_types or {}) do
          mapping[launch_type] = mapping[launch_type] or {}
          local seen = {}
          for _, filetype in ipairs(mapping[launch_type]) do
            seen[filetype] = true
          end
          for _, filetype in ipairs(spec.filetypes or {}) do
            if not seen[filetype] then
              table.insert(mapping[launch_type], filetype)
              seen[filetype] = true
            end
          end
        end
      end
      return mapping
    end

    dbg.vscode.snapshot_dap_configurations = function()
      local snapshot = {}
      for filetype, configurations in pairs(dap.configurations or {}) do
        snapshot[filetype] = vim.deepcopy(configurations)
      end
      return snapshot
    end

    dbg.vscode.collect_project_configurations = function(before)
      local project_configurations = {}
      for filetype, configurations in pairs(dap.configurations or {}) do
        if not vim.deep_equal(before[filetype], configurations) then
          project_configurations[filetype] = vim.deepcopy(configurations)
        end
      end
      return project_configurations
    end

    dbg.vscode.apply_project_baseline = function(project_state)
      if not project_state or type(project_state.baseline) ~= 'table' then
        return
      end

      for filetype, baseline_configurations in pairs(project_state.baseline) do
        if baseline_configurations == vim.NIL then
          dap.configurations[filetype] = nil
        else
          dap.configurations[filetype] = vim.deepcopy(baseline_configurations)
        end
      end
    end

    dbg.vscode.load_project_launch_json = function(launch_file)
      local ok, dap_vscode = pcall(require, 'dap.ext.vscode')
      if not ok then
        dprint('Failed to load dap.ext.vscode: ' .. tostring(dap_vscode))
        return false
      end

      local configs_ok, configurations = pcall(dap_vscode.getconfigs, launch_file)
      if not configs_ok then
        dprint('Failed to load project launch.json (' .. launch_file .. '): ' .. tostring(configurations))
        return false
      end

      local type_to_filetypes = dbg.vscode.build_launch_type_to_filetypes()
      for _, configuration in ipairs(configurations or {}) do
        if type(configuration) == 'table' and type(configuration.type) == 'string' then
          for _, filetype in ipairs(type_to_filetypes[configuration.type] or { configuration.type }) do
            local dap_configurations = dap.configurations[filetype] or {}
            for index = #dap_configurations, 1, -1 do
              if dap_configurations[index] and dap_configurations[index].name == configuration.name then
                table.remove(dap_configurations, index)
              end
            end
            table.insert(dap_configurations, vim.deepcopy(configuration))
            dap.configurations[filetype] = dap_configurations
          end
        end
      end

      return true
    end

    dbg.vscode.get_platform_key = function()
      if vim.fn.has('mac') == 1 then return 'osx' end
      if vim.fn.has('linux') == 1 then return 'linux' end
      if vim.fn.has('win32') == 1 then return 'windows' end
    end

    dbg.vscode.apply_platform_override = function(value)
      if type(value) ~= 'table' then
        return value
      end

      local copy = vim.deepcopy(value)
      local override = dbg.vscode.get_platform_key() and copy[dbg.vscode.get_platform_key()] or nil
      copy.osx = nil
      copy.linux = nil
      copy.windows = nil
      if type(override) == 'table' then
        copy = vim.tbl_deep_extend('force', copy, override)
      end
      return copy
    end

    dbg.vscode.expand_task_variables = function(value, ctx)
      if type(value) == 'table' then
        local result = {}
        for key, item in pairs(value) do
          result[key] = dbg.vscode.expand_task_variables(item, ctx)
        end
        return result
      end

      if type(value) ~= 'string' then
        return value
      end

      local prefix = '$' .. '{'
      local replacements = {
        [prefix .. 'workspaceFolder}'] = ctx.workspace_folder,
        [prefix .. 'workspaceRoot}'] = ctx.workspace_folder,
        [prefix .. 'workspaceFolderBasename}'] = ctx.workspace_folder_basename,
        [prefix .. 'cwd}'] = ctx.cwd,
        [prefix .. 'file}'] = ctx.file,
        [prefix .. 'fileBasename}'] = ctx.file_basename,
        [prefix .. 'fileDirname}'] = ctx.file_dirname,
        [prefix .. 'relativeFile}'] = ctx.relative_file,
        [prefix .. 'relativeFileDirname}'] = ctx.relative_file_dirname,
      }
      for token, replacement in pairs(replacements) do
        value = value:gsub(vim.pesc(token), replacement)
      end
      value = value:gsub(vim.pesc(prefix .. 'env:') .. '([^}]+)}', function(name)
        return vim.env[name] or ""
      end)
      return value
    end

    dbg.vscode.resolve_variable_context = function(root, bufnr)
      local file_path = bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_name(bufnr) or ""
      local normalized_root = vim.fs.normalize(root)
      local relative_file = file_path ~= ""
        and vim.fs.normalize(file_path):gsub('^' .. vim.pesc(normalized_root .. '/'), "")
        or ""

      return {
        workspace_folder = normalized_root,
        workspace_folder_basename = vim.fs.basename(normalized_root),
        cwd = vim.uv.cwd(),
        file = file_path,
        file_basename = file_path ~= "" and vim.fs.basename(file_path) or "",
        file_dirname = file_path ~= "" and vim.fs.dirname(file_path) or normalized_root,
        relative_file = relative_file,
        relative_file_dirname = relative_file ~= "" and vim.fs.dirname(relative_file) or ".",
      }
    end

    dbg.vscode.has_unsupported_task_variables = function(value)
      if type(value) == 'table' then
        for _, item in pairs(value) do
          if dbg.vscode.has_unsupported_task_variables(item) then
            return true
          end
        end
        return false
      end

      return type(value) == 'string' and value:match(vim.pesc('$' .. '{') .. '[^}]+' .. vim.pesc('}')) ~= nil
    end

    dbg.vscode.resolve_task_path = function(root, path)
      if type(path) ~= 'string' or path == "" then
        return root
      end

      local expanded = vim.fn.expand(path)
      if expanded:match('^/') or expanded:match('^~') or expanded:match('^%a:[/\\]') then
        return vim.fs.normalize(expanded)
      end

      return vim.fs.normalize(root .. '/' .. expanded)
    end

    dbg.vscode.split_shell_args = function(args)
      if type(args) ~= 'string' or args == "" then
        return {}
      end

      return vim.split(args, '%s+', { trimempty = true })
    end

    dbg.vscode.load_project_tasks_json = function(tasks_file)
      if not vim.uv.fs_stat(tasks_file) then
        return nil, 'tasks file does not exist'
      end

      local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(tasks_file), '\n'), { skip_comments = true })
      if not ok then
        return nil, 'Failed to parse tasks.json (' .. tasks_file .. '): ' .. tostring(data)
      end
      if type(data) ~= 'table' then
        return nil, 'tasks.json must contain a JSON object'
      end
      if data.version ~= nil and data.version ~= '2.0.0' then
        return nil, 'tasks.json version must be 2.0.0'
      end

      local by_label = {}
      local duplicate_labels = {}
      for _, task in ipairs(data.tasks or {}) do
        local normalized = dbg.helpers.normalize_task_profile(dbg.vscode.apply_platform_override(task))
        if type(normalized.label) == 'string' and normalized.label ~= "" then
          if by_label[normalized.label] then
            duplicate_labels[normalized.label] = true
          else
            by_label[normalized.label] = normalized
          end
        end
      end

      return { file = tasks_file, by_label = by_label, duplicate_labels = duplicate_labels }
    end

    dbg.vscode.resolve_project_task = function(project_state, task_label)
      if type(task_label) ~= 'string' or task_label == "" then
        return nil, 'Task label must be a non-empty string'
      end
      if project_state.tasks_error then
        return nil, project_state.tasks_error
      end
      if not project_state.tasks then
        return nil, 'No project task file was found for this project'
      end
      if project_state.tasks.duplicate_labels[task_label] then
        return nil, 'Duplicate task label found in project task files: ' .. task_label
      end
      return project_state.tasks.by_label[task_label], project_state.tasks.by_label[task_label] and nil or ('Task not found in project task files: ' .. task_label)
    end

    dbg.vscode.notify_task_status = function(message, level)
      dbg.helpers.set_task_status(message, level)
      vim.notify(message, level or vim.log.levels.INFO)
    end

    dbg.vscode.command_to_string = function(command)
      local parts = {}
      for _, part in ipairs(command or {}) do
        table.insert(parts, vim.fn.shellescape(tostring(part)))
      end
      return table.concat(parts, ' ')
    end

    dbg.vscode.normalize_spawn_env = function(env)
      local merged = vim.fn.environ()
      for key, value in pairs(env or {}) do
        merged[tostring(key)] = tostring(value)
      end
      local normalized = {}
      for key, value in pairs(merged) do
        table.insert(normalized, tostring(key) .. '=' .. tostring(value))
      end
      table.sort(normalized)
      return normalized
    end

    dbg.vscode.get_task_runtime_options = function(task)
      local runtime = type(task.nixvim) == 'table' and task.nixvim or {}
      return {
        timeout_ms = tonumber(runtime.timeout_ms) or dbg.state.task_defaults.timeout_ms,
        output = runtime.output == 'float' and 'float' or dbg.state.task_output.mode,
      }
    end

    dbg.vscode.build_task_command = function(task, root, bufnr)
      local resolved_task = dbg.vscode.expand_task_variables(task, dbg.vscode.resolve_variable_context(root, bufnr))
      if dbg.vscode.has_unsupported_task_variables(resolved_task.command)
        or dbg.vscode.has_unsupported_task_variables(resolved_task.args)
        or dbg.vscode.has_unsupported_task_variables((resolved_task.options or {}).cwd)
        or dbg.vscode.has_unsupported_task_variables((resolved_task.options or {}).env) then
        return nil, 'Unsupported task variable found in `' .. (resolved_task.label or 'task') .. '`'
      end
      if resolved_task.isBackground then
        return nil, 'Task `' .. (resolved_task.label or 'task') .. '` uses unsupported isBackground=true'
      end
      if type(resolved_task.command) ~= 'string' or resolved_task.command == "" then
        return nil, 'Task `' .. (resolved_task.label or 'task') .. '` is missing a command'
      end
      if resolved_task.type ~= 'shell' and resolved_task.type ~= 'process' then
        return nil, 'Task `' .. (resolved_task.label or 'task') .. '` uses unsupported type `' .. tostring(resolved_task.type) .. '`'
      end

      local options = resolved_task.options or {}
      local cwd = dbg.vscode.resolve_task_path(root, options.cwd)
      if not vim.uv.fs_stat(cwd) then
        return nil, 'Task `' .. (resolved_task.label or 'task') .. '` uses missing cwd `' .. cwd .. '`'
      end

      if resolved_task.type == 'process' then
        local command = { resolved_task.command }
        for _, arg in ipairs(resolved_task.args or {}) do
          table.insert(command, tostring(arg))
        end
        return { cmd = command, cwd = cwd, env = options.env and vim.deepcopy(options.env) or nil }
      end

      local command_line = resolved_task.command
      for _, arg in ipairs(resolved_task.args or {}) do
        command_line = command_line .. ' ' .. vim.fn.shellescape(tostring(arg))
      end
      local shell = options.shell or {}
      local command = { shell.executable or vim.o.shell }
      vim.list_extend(command, shell.args or dbg.vscode.split_shell_args(vim.o.shellcmdflag))
      table.insert(command, command_line)
      return { cmd = command, cwd = cwd, env = options.env and vim.deepcopy(options.env) or nil }
    end

    dbg.vscode.collect_task_execution_plan = function(project_state, task_label, bufnr, seen, plan)
      seen = seen or {}
      plan = plan or {}
      if seen[task_label] then
        return nil, 'Circular task dependency detected for `' .. task_label .. '`'
      end

      local task, resolve_err = dbg.vscode.resolve_project_task(project_state, task_label)
      if not task then
        return nil, resolve_err
      end

      seen[task_label] = true
      if task.dependsOn ~= nil then
        local dependencies = type(task.dependsOn) == 'table' and task.dependsOn or { task.dependsOn }
        for _, dependency in ipairs(dependencies) do
          local dependency_plan, err = dbg.vscode.collect_task_execution_plan(project_state, dependency, bufnr, seen, plan)
          if not dependency_plan then
            seen[task_label] = nil
            return nil, err
          end
        end
      end

      local command_spec, command_err = dbg.vscode.build_task_command(task, project_state.root, bufnr)
      if not command_spec then
        seen[task_label] = nil
        return nil, command_err
      end

      table.insert(plan, {
        label = task_label,
        project_root = project_state.root,
        task = task,
        runtime = dbg.vscode.get_task_runtime_options(task),
        command_spec = command_spec,
      })
      seen[task_label] = nil
      return plan
    end

    dbg.vscode.run_task_plan_async = function(plan, context, on_complete)
      local index = 1

      local function finish(ok, err)
        if on_complete then
          on_complete(ok, err)
        end
      end

      local function finish_with_failure(run_id, entry, status, err, message)
        dbg.helpers.append_task_output(run_id, 'stderr', message .. '\n')
        dbg.helpers.finish_task_run(run_id, status, message, status == 'failed' and vim.log.levels.ERROR or vim.log.levels.WARN)
        vim.notify(message .. (err and ('\n' .. err) or ""), status == 'failed' and vim.log.levels.ERROR or vim.log.levels.WARN)
        finish(false, err or message)
      end

      local function start_task_process(run_id, entry, on_exit)
        local run = dbg.helpers.get_active_task_run(run_id)
        if not run then
          on_exit(false, 'Task state disappeared')
          return
        end

        local stdout = vim.uv.new_pipe(false)
        local stderr = vim.uv.new_pipe(false)
        run.stdout = stdout
        run.stderr = stderr

        local function close_pipe(pipe)
          if pipe and not pipe:is_closing() then
            pcall(vim.uv.read_stop, pipe)
            pipe:close()
          end
        end

        local command = entry.command_spec.cmd or {}
        if type(command[1]) ~= 'string' or command[1] == "" then
          close_pipe(stdout)
          close_pipe(stderr)
          on_exit(false, 'Task command is empty')
          return
        end

        local handle
        local exit_reported = false

        local function finalize(ok, err)
          if exit_reported then
            return
          end
          exit_reported = true
          close_pipe(stdout)
          close_pipe(stderr)
          on_exit(ok, err)
        end

        handle = vim.uv.spawn(command[1], {
          args = vim.list_slice(command, 2),
          cwd = entry.command_spec.cwd,
          env = dbg.vscode.normalize_spawn_env(entry.command_spec.env),
          stdio = { nil, stdout, stderr },
        }, function(code, signal)
          vim.schedule(function()
            local current = dbg.helpers.get_active_task_run(run_id)
            if current and current.timed_out then
              finalize(false, 'Task timed out after ' .. tostring(math.floor((entry.runtime.timeout_ms or 0) / 1000)) .. 's')
            elseif current and current.canceled then
              finalize(false, current.cancel_reason or 'Task canceled')
            elseif code ~= 0 then
              local detail = signal ~= 0 and ('signal ' .. tostring(signal)) or ('exit code ' .. tostring(code))
              finalize(false, 'Task exited with ' .. detail)
            else
              finalize(true)
            end
          end)
        end)

        if not handle then
          finalize(false, 'Failed to start task process')
          return
        end

        run.handle = handle

        vim.uv.read_start(stdout, function(read_err, data)
          vim.schedule(function()
            if read_err then
              dbg.helpers.append_task_output(run_id, 'stderr', 'stdout error: ' .. tostring(read_err) .. '\n')
              return
            end
            if data then
              dbg.helpers.append_task_output(run_id, 'stdout', data)
            end
          end)
        end)

        vim.uv.read_start(stderr, function(read_err, data)
          vim.schedule(function()
            if read_err then
              dbg.helpers.append_task_output(run_id, 'stderr', 'stderr error: ' .. tostring(read_err) .. '\n')
              return
            end
            if data then
              dbg.helpers.append_task_output(run_id, 'stderr', data)
            end
          end)
        end)

        dbg.helpers.start_task_timeout(run_id, entry.runtime.timeout_ms, function(current)
          dbg.helpers.append_task_output(run_id, 'stderr', 'Task timeout reached: ' .. entry.label .. '\n')
          dbg.helpers.cancel_task_run(current.id, 'Task timed out')
        end)
      end

      local function run_next()
        local entry = plan[index]
        if not entry then
          local done_message = 'Completed ' .. context.phase .. ': ' .. context.root_label
          dbg.helpers.set_task_status(done_message, vim.log.levels.INFO)
          vim.notify(done_message, vim.log.levels.INFO)
          finish(true)
          return
        end

        local run_id = dbg.helpers.start_task_run({
          label = entry.label,
          phase = context.phase,
          project_root = context.project_root,
          runtime = entry.runtime,
        })

        local start_message = 'Running ' .. context.phase .. ': ' .. entry.label
        dbg.vscode.notify_task_status(start_message, vim.log.levels.INFO)

        dbg.helpers.reset_task_output(run_id, 'Debug task: ' .. entry.label .. ' (' .. context.phase .. ')')
        dbg.helpers.show_task_output(run_id, entry.runtime.output)
        dbg.helpers.append_task_output(run_id, 'stdout', '$ ' .. dbg.vscode.command_to_string(entry.command_spec.cmd) .. '\n')
        dbg.helpers.append_task_output(run_id, 'stdout', 'cwd: ' .. entry.command_spec.cwd .. '\n\n')

        start_task_process(run_id, entry, function(ok, err)
          local status = 'completed'
          local message = 'Completed ' .. context.phase .. ': ' .. entry.label
          local level = vim.log.levels.INFO

          local run = dbg.helpers.get_active_task_run(run_id)
          if run and run.timed_out then
            status = 'timeout'
            message = 'Timed out ' .. context.phase .. ': ' .. entry.label
            level = vim.log.levels.WARN
          elseif run and run.canceled then
            status = 'canceled'
            message = 'Canceled ' .. context.phase .. ': ' .. entry.label
            level = vim.log.levels.WARN
          elseif not ok then
            status = 'failed'
            message = 'Failed ' .. context.phase .. ': ' .. entry.label
            level = vim.log.levels.ERROR
          end

          if not ok then
            finish_with_failure(run_id, entry, status, err, message)
            return
          end

          dbg.helpers.append_task_output(run_id, 'stdout', message .. '\n\n')
          dbg.helpers.finish_task_run(run_id, status, message, level)
          vim.notify(message, level)
          index = index + 1
          run_next()
        end)
      end

      run_next()
    end

    dbg.vscode.run_project_task_async = function(project_state, task_label, phase, bufnr, on_complete)
      local plan, err = dbg.vscode.collect_task_execution_plan(project_state, task_label, bufnr)
      if not plan then
        if on_complete then
          on_complete(false, err)
        end
        return
      end

      dbg.vscode.run_task_plan_async(plan, {
        phase = phase,
        root_label = task_label,
        project_root = project_state.root,
      }, on_complete)
    end

    dbg.vscode.get_project_task_items = function(bufnr)
      local root = dbg.vscode.get_project_debug_root_for_buffer(bufnr)
      local project_state = root and dbg.state.project_registry[root] or nil
      if not project_state or not project_state.tasks or type(project_state.tasks.by_label) ~= 'table' then
        return {}
      end

      local items = {}
      for label, task in pairs(project_state.tasks.by_label) do
        if not project_state.tasks.duplicate_labels[label] then
          table.insert(items, {
            label = label,
            text = label,
            task = vim.deepcopy(task),
            project_root = root,
          })
        end
      end

      table.sort(items, function(left, right)
        return left.label < right.label
      end)

      return items
    end

    dbg.vscode.run_project_task_picker = function()
      local bufnr = vim.api.nvim_get_current_buf()
      dbg.vscode.load_project_debug_config(bufnr, true)

      local items = dbg.vscode.get_project_task_items(bufnr)
      if #items == 0 then
        vim.notify('No project tasks found. Add .vscode/tasks.json or .nvim/tasks.lua for this project.', vim.log.levels.ERROR)
        return
      end

      local function run_item(item)
        if not item then
          return
        end

        local project_state = dbg.state.project_registry[item.project_root]
        if not project_state then
          vim.notify('Project task state is not available', vim.log.levels.ERROR)
          return
        end

        dbg.vscode.run_project_task_async(project_state, item.label, 'task', bufnr, function(ok, err)
          if not ok then
            vim.notify('Task failed: ' .. tostring(err), vim.log.levels.ERROR)
          end
        end)
      end

      vim.ui.select(items, {
        prompt = 'Project tasks',
        format_item = function(item)
          return item.text
        end,
      }, run_item)
    end

    dbg.vscode.attach_post_debug_task = function(session, context)
      if session and context and context.task_label then
        dbg.state.session_task_registry[session] = { context = context, completed = false }
      end
    end

    dbg.vscode.finalize_debug_session_task = function(session)
      local entry = dbg.state.session_task_registry[session]
      if not entry or entry.completed then
        return
      end

      entry.completed = true
      dbg.vscode.run_project_task_async(entry.context.project_state, entry.context.task_label, 'postDebugTask', entry.context.bufnr, function(ok, err)
        if not ok then
          vim.notify('postDebugTask failed: ' .. tostring(err), vim.log.levels.WARN)
        end
        dbg.state.session_task_registry[session] = nil
      end)
    end

    dbg.vscode.get_project_debug_root_for_buffer = function(bufnr)
      local marker = dbg.project_dap.find_project_dap_file(bufnr)
        or dbg.project_dap.find_project_tasks_file(bufnr)
        or dbg.vscode.find_project_launch_file(bufnr)
        or dbg.vscode.find_project_tasks_file(bufnr)
      return marker and dbg.helpers.find_project_root_from_marker_path(marker) or nil
    end

    dbg.vscode.load_project_debug_config = function(bufnr, force_reload)
      local target_bufnr = bufnr or vim.api.nvim_get_current_buf()
      local dap_file = dbg.project_dap.find_project_dap_file(target_bufnr)
      local project_tasks_file = dbg.project_dap.find_project_tasks_file(target_bufnr)
      local launch_file = dbg.vscode.find_project_launch_file(target_bufnr)
      local tasks_file = dbg.vscode.find_project_tasks_file(target_bufnr)
      if not dap_file and not project_tasks_file and not launch_file and not tasks_file then
        return
      end

      local root = dbg.helpers.find_project_root_from_marker_path(dap_file or project_tasks_file or launch_file or tasks_file)
      local current_signature = dbg.vscode.build_project_signature({ dap_file, project_tasks_file, launch_file, tasks_file })
      if not force_reload and dbg.state.project_registry[root] and dbg.state.project_registry[root].signature == current_signature then
        return
      end

      dbg.vscode.apply_project_baseline(dbg.state.project_registry[root])
      local before_configurations = dbg.vscode.snapshot_dap_configurations()

      if launch_file then
        dbg.vscode.load_project_launch_json(launch_file)
      end
      if dap_file then
        dbg.project_dap.load_project_dap_file(dap_file, target_bufnr)
      end

      local tasks_sources = {}
      local tasks_error = nil
      if tasks_file then
        local vscode_tasks, vscode_tasks_error = dbg.vscode.load_project_tasks_json(tasks_file)
        if vscode_tasks_error then
          tasks_error = vscode_tasks_error
        elseif vscode_tasks then
          table.insert(tasks_sources, vscode_tasks)
        end
      end
      if project_tasks_file then
        local project_tasks, project_tasks_error = dbg.project_dap.load_project_tasks_file(project_tasks_file, target_bufnr)
        if project_tasks_error then
          tasks_error = project_tasks_error
        elseif project_tasks then
          table.insert(tasks_sources, project_tasks)
        end
      end

      local tasks = { by_label = {}, duplicate_labels = {}, files = {} }
      for _, source in ipairs(tasks_sources) do
        table.insert(tasks.files, source.file)
        for label, task in pairs(source.by_label or {}) do
          if tasks.by_label[label] then
            tasks.duplicate_labels[label] = true
          else
            tasks.by_label[label] = task
          end
        end
        for label, duplicate in pairs(source.duplicate_labels or {}) do
          if duplicate then
            tasks.duplicate_labels[label] = true
          end
        end
      end
      if vim.tbl_isempty(tasks.by_label) and #tasks.files == 0 then
        tasks = nil
      end

      local project_configurations = dbg.vscode.collect_project_configurations(before_configurations)
      local baseline = {}
      for filetype, _ in pairs(project_configurations) do
        baseline[filetype] = before_configurations[filetype] ~= nil and vim.deepcopy(before_configurations[filetype]) or vim.NIL
      end

      dbg.state.project_registry[root] = {
        root = root,
        dap_file = dap_file,
        project_tasks_file = project_tasks_file,
        launch_file = launch_file,
        tasks_file = tasks_file,
        tasks = tasks,
        tasks_error = tasks_error,
        configurations = project_configurations,
        baseline = baseline,
        signature = current_signature,
      }
    end

    dbg.vscode.get_project_config_items = function(bufnr)
      local root = dbg.vscode.get_project_debug_root_for_buffer(bufnr)
      local project_state = root and dbg.state.project_registry[root] or nil
      if not project_state or type(project_state.configurations) ~= 'table' then
        return {}
      end

      local items_by_key = {}
      for filetype, configurations in pairs(project_state.configurations) do
        for _, configuration in ipairs(configurations or {}) do
          items_by_key[filetype .. '\0' .. (configuration.name or 'Unnamed config')] = {
            filetype = filetype,
            label = (configuration.name or 'Unnamed config') .. ' [' .. filetype .. ']',
            project_root = root,
            config = vim.deepcopy(configuration),
            sort_priority = filetype == vim.bo[bufnr].filetype and 0 or 1,
          }
        end
      end

      local items = {}
      for _, item in pairs(items_by_key) do
        table.insert(items, item)
      end
      table.sort(items, function(left, right)
        if left.sort_priority == right.sort_priority then
          return left.label < right.label
        end
        return left.sort_priority < right.sort_priority
      end)
      return items
    end

    dbg.vscode.run_project_debug_item = function(item, no_debug)
      local project_state = dbg.state.project_registry[item.project_root]
      if not project_state then
        vim.notify('Project debug state is not available', vim.log.levels.ERROR)
        return
      end

      local config = vim.deepcopy(item.config)
      local bufnr = vim.api.nvim_get_current_buf()
      local pre_launch_task = config.preLaunchTask
      local post_debug_task = config.postDebugTask
      if no_debug then
        config.noDebug = true
      end
      config.preLaunchTask = nil
      config.postDebugTask = nil

      config.__nixvim_post_debug_task_context = post_debug_task and {
        project_state = project_state,
        task_label = post_debug_task,
        bufnr = bufnr,
      } or nil

      local function start_debug_session()
        local ok, err = pcall(dap.run, config)
        if not ok then
          vim.notify('Failed to start debug session: ' .. tostring(err), vim.log.levels.ERROR)
        end
      end

      if pre_launch_task then
        dbg.vscode.run_project_task_async(project_state, pre_launch_task, 'preLaunchTask', bufnr, function(ok, err)
          if not ok then
            vim.notify('preLaunchTask failed: ' .. tostring(err), vim.log.levels.ERROR)
            return
          end
          start_debug_session()
        end)
        return
      end

      start_debug_session()
    end

    dbg.vscode.run_project_debug_config = function(no_debug)
      local bufnr = vim.api.nvim_get_current_buf()
      if _G.load_project_breakpoints_for_project then
        _G.load_project_breakpoints_for_project(bufnr, true)
      end
      if not no_debug and dap.session() then
        dap.continue()
        return
      end

      dbg.vscode.load_project_debug_config(bufnr, true)
      local items = dbg.vscode.get_project_config_items(bufnr)
      if #items == 0 then
        vim.notify('No project DAP configurations found. Add .vscode/launch.json or create .nvim/dap.lua with <leader>dC.', vim.log.levels.ERROR)
        return
      end
      if #items == 1 then
        dbg.vscode.run_project_debug_item(items[1], no_debug)
        return
      end

      vim.ui.select(items, {
        prompt = 'Project debug configurations',
        format_item = function(item)
          return item.label
        end,
      }, function(item)
        if item and item.config then
          dbg.vscode.run_project_debug_item(item, no_debug)
        end
      end)
    end

    vim.api.nvim_create_user_command('DapLoadProjectConfig', function()
      dbg.vscode.load_project_debug_config(vim.api.nvim_get_current_buf(), true)
    end, { desc = 'Reload project DAP config files' })

    vim.api.nvim_create_user_command('DapTaskOutput', function()
      dbg.helpers.show_task_output()
    end, { desc = 'Show debug task output' })

    vim.api.nvim_create_user_command('DapTaskRuns', function()
      dbg.helpers.pick_recent_task_run()
    end, { desc = 'Show recent debug task runs' })

    vim.api.nvim_create_user_command('ProjectTasks', function()
      dbg.vscode.run_project_task_picker()
    end, { desc = 'Run a project task from .vscode/tasks.json or .nvim/tasks.lua' })

    vim.api.nvim_create_user_command('DapCancelTask', function()
      if dbg.helpers.cancel_all_task_runs('Canceled by user') then
        dbg.vscode.notify_task_status('Canceling running debug tasks', vim.log.levels.WARN)
      else
        vim.notify('No running debug tasks to cancel', vim.log.levels.INFO)
      end
    end, { desc = 'Cancel running debug tasks' })

    vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
      callback = function(args)
        if vim.api.nvim_get_option_value('buftype', { buf = args.buf }) == "" then
          dbg.vscode.load_project_debug_config(args.buf, false)
        end
      end,
      desc = 'Load project DAP config on buffer open',
    })

    dap.listeners.after.event_initialized.nixvim_vscode_tasks = function(session)
      local context = session and session.config and session.config.__nixvim_post_debug_task_context or nil
      if session and context then
        dbg.vscode.attach_post_debug_task(session, context)
      end
    end
    dap.listeners.before.event_terminated.nixvim_vscode_tasks = dbg.vscode.finalize_debug_session_task
    dap.listeners.before.event_exited.nixvim_vscode_tasks = dbg.vscode.finalize_debug_session_task
    dap.listeners.before.disconnect.nixvim_vscode_tasks = dbg.vscode.finalize_debug_session_task
  '';
in
{
  inherit lua name;
}
