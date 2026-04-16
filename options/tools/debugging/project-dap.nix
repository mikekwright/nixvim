{ ... }:

let
  name = "tools.debugging";

  lua = /* lua */ ''
    local dbg = _G.nixvim_debugger
    local dap = require('dap')

    dbg.project_dap.find_project_dap_file = function(bufnr)
      return dbg.helpers.find_nearest_navigating_up(bufnr, '.nvim/dap.lua')
    end

    dbg.project_dap.find_project_tasks_file = function(bufnr)
      return dbg.helpers.find_nearest_navigating_up(bufnr, '.nvim/tasks.lua')
    end

    dbg.project_dap.detect_debug_root = function(bufnr)
      return dbg.helpers.detect_project_root(bufnr, {
        '.vscode/launch.json',
        '.vscode/tasks.json',
        '.nvim/dap.lua',
        '.nvim/tasks.lua',
      })
    end

    dbg.project_dap.get_language_choices = function(current_spec)
      local choices = {}
      if current_spec then
        table.insert(choices, current_spec.id)
      end

      for _, language in ipairs(dbg.helpers.get_registered_language_ids()) do
        if not current_spec or language ~= current_spec.id then
          table.insert(choices, language)
        end
      end

      return choices
    end

    dbg.project_dap.select_debug_language = function(current_spec, callback)
      local choices = dbg.project_dap.get_language_choices(current_spec)
      if #choices == 0 then
        vim.notify('No language-specific debug config generators are registered in this package', vim.log.levels.WARN)
        return
      end

      vim.ui.select(choices, {
        prompt = 'Select debug language',
        format_item = function(language)
          local spec = dbg.helpers.get_debug_language(language)
          local label = spec and spec.label or language
          if current_spec and language == current_spec.id then
            return label .. ' (current file)'
          end
          return label
        end,
      }, callback)
    end

    dbg.project_dap.extract_template_body = function(template)
      local lines = vim.split(template, '\n', { plain = true })
      if #lines < 2 then
        return nil
      end

      if lines[1]:match('^return function%(ctx%)') then
        table.remove(lines, 1)
      end

      while #lines > 0 and lines[#lines]:match('^%s*$') do
        table.remove(lines, #lines)
      end

      if #lines > 0 and lines[#lines]:match('^end%s*$') then
        table.remove(lines, #lines)
      end

      while #lines > 0 and lines[1]:match('^%s*$') do
        table.remove(lines, 1)
      end

      while #lines > 0 and lines[#lines]:match('^%s*$') do
        table.remove(lines, #lines)
      end

      return lines
    end

    dbg.project_dap.normalize_project_task_collection = function(result, tasks_file)
      local tasks = result
      if type(tasks) ~= 'table' then
        return nil, 'Project tasks file must return a table: ' .. tasks_file
      end

      if type(tasks.tasks) == 'table' then
        tasks = tasks.tasks
      end

      local by_label = {}
      local duplicate_labels = {}

      if vim.islist(tasks) then
        for _, task in ipairs(tasks) do
          if type(task) == 'table' then
            local normalized = dbg.helpers.normalize_task_profile(task)
            local label = normalized.label or normalized.name or normalized.id
            if type(label) == 'string' and label ~= "" then
              normalized.label = label
              if by_label[label] then
                duplicate_labels[label] = true
              else
                by_label[label] = normalized
              end
            end
          end
        end
      else
        for label, task in pairs(tasks) do
          if type(label) == 'string' and type(task) == 'table' then
            local normalized = dbg.helpers.normalize_task_profile(vim.tbl_extend('keep', task, { label = label }))
            if by_label[label] then
              duplicate_labels[label] = true
            else
              by_label[label] = normalized
            end
          end
        end
      end

      return {
        file = tasks_file,
        by_label = by_label,
        duplicate_labels = duplicate_labels,
      }
    end

    dbg.project_dap.load_project_tasks_file = function(tasks_file, bufnr)
      local chunk, err = loadfile(tasks_file)
      if not chunk then
        return nil, 'Failed to parse project tasks.lua (' .. tasks_file .. '): ' .. tostring(err)
      end

      local ok, result = pcall(chunk)
      if not ok then
        return nil, 'Failed to load project tasks.lua (' .. tasks_file .. '): ' .. tostring(result)
      end

      if type(result) == 'function' then
        local project_ok, project_result = pcall(result, {
          dap = dap,
          root = dbg.helpers.find_project_root_from_marker_path(tasks_file),
          bufnr = bufnr,
          filetype = bufnr and vim.bo[bufnr].filetype or vim.bo.filetype,
        })
        if not project_ok then
          return nil, 'Failed to run project tasks.lua (' .. tasks_file .. '): ' .. tostring(project_result)
        end
        result = project_result
      end

      return dbg.project_dap.normalize_project_task_collection(result, tasks_file)
    end

    dbg.project_dap.apply_project_configurations = function(result, bufnr)
      local configurations = type(result.configurations) == 'table' and result.configurations or result
      local default_filetype = bufnr and vim.bo[bufnr].filetype or vim.bo.filetype

      local function apply_configuration(filetype, configuration)
        if type(filetype) ~= 'string' or filetype == "" or type(configuration) ~= 'table' then
          return
        end

        local normalized = dbg.helpers.normalize_launch_profile(configuration)
        local dap_configurations = dap.configurations[filetype] or {}

        for index = #dap_configurations, 1, -1 do
          if dap_configurations[index] and dap_configurations[index].name == normalized.name then
            table.remove(dap_configurations, index)
          end
        end

        normalized.filetypes = nil
        table.insert(dap_configurations, normalized)
        dap.configurations[filetype] = dap_configurations
      end

      local function apply_list(filetype, items)
        for _, configuration in ipairs(items or {}) do
          local filetypes = configuration.filetypes
          if type(filetypes) == 'table' and #filetypes > 0 then
            for _, target_filetype in ipairs(filetypes) do
              apply_configuration(target_filetype, configuration)
            end
          else
            apply_configuration(filetype, configuration)
          end
        end
      end

      if vim.islist(configurations) then
        apply_list(default_filetype, configurations)
        return true
      end

      for filetype, items in pairs(configurations or {}) do
        if vim.islist(items) then
          apply_list(filetype, items)
        elseif type(items) == 'table' then
          apply_configuration(filetype, items)
        end
      end

      return true
    end

    dbg.project_dap.load_project_dap_file = function(dap_file, bufnr)
      local chunk, err = loadfile(dap_file)
      if not chunk then
        dprint('Failed to parse project dap.lua (' .. dap_file .. '): ' .. tostring(err))
        return false
      end

      local ok, result = pcall(chunk)
      if not ok then
        dprint('Failed to load project dap.lua (' .. dap_file .. '): ' .. tostring(result))
        return false
      end

      if type(result) == 'function' then
        local project_ok, project_result = pcall(result, {
          dap = dap,
          root = dbg.helpers.find_project_root_from_marker_path(dap_file),
          bufnr = bufnr,
          filetype = vim.bo[bufnr].filetype,
        })
        if not project_ok then
          dprint('Failed to run project dap.lua (' .. dap_file .. '): ' .. tostring(project_result))
          return false
        end
        result = project_result
      end

      if type(result) == 'table' then
        return dbg.project_dap.apply_project_configurations(result, bufnr)
      end

      return true
    end

    dbg.project_dap.append_language_template_to_current_dap = function(language)
      local spec = dbg.helpers.get_debug_language(language)
      if not spec or type(spec.templates) ~= 'table' or type(spec.templates['dap.lua']) ~= 'string' then
        vim.notify('No .nvim/dap.lua template is registered for ' .. language, vim.log.levels.WARN)
        return
      end

      local body_lines = dbg.project_dap.extract_template_body(spec.templates['dap.lua'])
      if not body_lines or #body_lines == 0 then
        vim.notify('Could not extract template body for ' .. language, vim.log.levels.WARN)
        return
      end

      local bufnr = vim.api.nvim_get_current_buf()
      local line_count = vim.api.nvim_buf_line_count(bufnr)
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, line_count, false)
      local insert_at = line_count

      for i = line_count, 1, -1 do
        if lines[i]:match('^end%s*$') then
          insert_at = i - 1
          break
        end
      end

      local block = { "", '  -- ' .. (spec.label or language) .. ' project configuration' }
      vim.list_extend(block, body_lines)

      vim.api.nvim_buf_set_lines(bufnr, insert_at, insert_at, false, block)
      vim.notify('Added ' .. (spec.label or language) .. ' entry to .nvim/dap.lua', vim.log.levels.INFO)
    end

    dbg.project_dap.create_project_debug_config = function()
      local bufnr = vim.api.nvim_get_current_buf()
      local buffer_name = vim.api.nvim_buf_get_name(bufnr)
      local project_dap_file = dbg.project_dap.find_project_dap_file(bufnr)
      local current_spec = dbg.helpers.get_debug_language_for_filetype(vim.bo.filetype)

      if project_dap_file and buffer_name ~= "" and vim.fs.normalize(buffer_name) == vim.fs.normalize(project_dap_file) then
        dbg.project_dap.select_debug_language(current_spec, function(language)
          if language then
            dbg.project_dap.append_language_template_to_current_dap(language)
          end
        end)
        return
      end

      if project_dap_file and vim.fn.filereadable(project_dap_file) == 1 then
        vim.cmd('edit ' .. vim.fn.fnameescape(project_dap_file))
        vim.notify('Opened .nvim/dap.lua', vim.log.levels.INFO)
        return
      end

      dbg.project_dap.select_debug_language(current_spec, function(language)
        if not language then
          return
        end

        local spec = dbg.helpers.get_debug_language(language)
        if not spec or type(spec.templates) ~= 'table' or type(spec.templates['dap.lua']) ~= 'string' then
          vim.notify('No .nvim/dap.lua template is registered for ' .. language, vim.log.levels.WARN)
          return
        end

        local root = dbg.project_dap.detect_debug_root(bufnr) or vim.uv.cwd()
        local full_path = root .. '/.nvim/dap.lua'
        vim.fn.mkdir(vim.fs.dirname(full_path), 'p')

        if vim.fn.filereadable(full_path) ~= 1 then
          vim.fn.writefile(vim.split(spec.templates['dap.lua'], '\n', { plain = true }), full_path)
        end

        vim.cmd('edit ' .. vim.fn.fnameescape(full_path))
        vim.notify('Opened .nvim/dap.lua for ' .. (spec.label or language) .. ' debug configuration', vim.log.levels.INFO)
      end)
    end

    dbg.project_dap.show_debug_guidance = function()
      local bufnr = vim.api.nvim_get_current_buf()
      local filetype = vim.bo[bufnr].filetype
      local root = dbg.project_dap.detect_debug_root(bufnr)
      local spec = dbg.helpers.get_debug_language_for_filetype(filetype) or dbg.helpers.get_debug_language_for_root(root)
      local guidance = spec and spec.guidance or table.concat({
        'No debug guidance is registered for `' .. (filetype ~= "" and filetype or 'this buffer') .. '`.',
        "",
        'Use <leader>dc once a DAP adapter/configuration has been added for this project.',
        'Project-local configs can live in .vscode/launch.json or .nvim/dap.lua.',
        'Project-local tasks can live in .vscode/tasks.json or .nvim/tasks.lua.',
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
  '';
in
{
  inherit lua name;
}
