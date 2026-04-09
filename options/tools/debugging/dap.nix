{ ... }:

let
  name = "tools.debugging";

  lua = /* lua */ ''
    local dbg = _G.nixvim_debugging
    local dap = require('dap')

    --
    -- DapUI Elements
    --
    local dapui = require('dapui')

    dapui.setup()

    local open_dap_ui = function() dapui.open() end
    local close_dap_ui = function() dapui.close() end
    local toggle_dap_ui = function() dapui.toggle() end

    dap.listeners.before.attach.dapui_config = open_dap_ui 
    dap.listeners.before.launch.dapui_config = open_dap_ui
    dap.listeners.before.event_terminated.dapui_config = close_dap_ui
    dap.listeners.before.event_exited.dapui_config = close_dap_ui
    dap.listeners.before.disconnect.dapui_config = close_dap_ui

    keymapd('<leader>du', 'Debug: Toggle UI', toggle_dap_ui)

    -- 
    -- Nixvim Debug support flows
    --

    dbg.dap.find_project_dap_file = function(bufnr)
      return dbg.helpers.find_nearest_navigating_up(bufnr, '.nvim/dap.lua')
    end

    dbg.dap.detect_debug_root = function(bufnr)
      return dbg.helpers.detect_project_root(bufnr, { '.vscode/launch.json', '.vscode/tasks.json', '.nvim/dap.lua' })
    end

    dbg.dap.load_project_dap_file = function(dap_file, bufnr)
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
          local project_ok, project_err = pcall(result, {
            dap = dap,
            root = dbg.helpers.find_project_root_from_marker_path(dap_file),
            bufnr = bufnr,
            filetype = vim.bo[bufnr].filetype,
          })
        if not project_ok then
          dprint('Failed to run project dap.lua (' .. dap_file .. '): ' .. tostring(project_err))
          return false
        end
      end

      return true
    end

    dbg.dap.get_language_choices = function(current_spec)
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

    dbg.dap.select_debug_language = function(current_spec, callback)
      local choices = dbg.dap.get_language_choices(current_spec)
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

    dbg.dap.extract_template_body = function(template)
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

    dbg.dap.append_language_template_to_current_dap = function(language)
      local spec = dbg.helpers.get_debug_language(language)
      if not spec or type(spec.templates) ~= 'table' or type(spec.templates['dap.lua']) ~= 'string' then
        vim.notify('No .nvim/dap.lua template is registered for ' .. language, vim.log.levels.WARN)
        return
      end

      local body_lines = dbg.dap.extract_template_body(spec.templates['dap.lua'])
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

    dbg.dap.create_project_debug_config = function()
      local bufnr = vim.api.nvim_get_current_buf()
      local buffer_name = vim.api.nvim_buf_get_name(bufnr)
      local project_dap_file = dbg.dap.find_project_dap_file(bufnr)
      local current_spec = dbg.helpers.get_debug_language_for_filetype(vim.bo.filetype)

      if project_dap_file and buffer_name ~= "" and vim.fs.normalize(buffer_name) == vim.fs.normalize(project_dap_file) then
        dbg.dap.select_debug_language(current_spec, function(language)
          if language then
            dbg.dap.append_language_template_to_current_dap(language)
          end
        end)
        return
      end

      if project_dap_file and vim.fn.filereadable(project_dap_file) == 1 then
        vim.cmd('edit ' .. vim.fn.fnameescape(project_dap_file))
        vim.notify('Opened .nvim/dap.lua', vim.log.levels.INFO)
        return
      end

      dbg.dap.select_debug_language(current_spec, function(language)
        if not language then
          return
        end

        local spec = dbg.helpers.get_debug_language(language)
        if not spec or type(spec.templates) ~= 'table' or type(spec.templates['dap.lua']) ~= 'string' then
          vim.notify('No .nvim/dap.lua template is registered for ' .. language, vim.log.levels.WARN)
          return
        end

        local root = dbg.dap.detect_debug_root(bufnr) or vim.uv.cwd()
        local full_path = root .. '/.nvim/dap.lua'
        vim.fn.mkdir(vim.fs.dirname(full_path), 'p')

        if vim.fn.filereadable(full_path) ~= 1 then
          vim.fn.writefile(vim.split(spec.templates['dap.lua'], '\n', { plain = true }), full_path)
        end

        vim.cmd('edit ' .. vim.fn.fnameescape(full_path))
        vim.notify('Opened .nvim/dap.lua for ' .. (spec.label or language) .. ' debug configuration', vim.log.levels.INFO)
      end)
    end

    dbg.dap.show_debug_guidance = function()
      local bufnr = vim.api.nvim_get_current_buf()
      local filetype = vim.bo[bufnr].filetype
      local root = dbg.dap.detect_debug_root(bufnr)
      local spec = dbg.helpers.get_debug_language_for_filetype(filetype) or dbg.helpers.get_debug_language_for_root(root)
      local guidance = spec and spec.guidance or table.concat({
        'No debug guidance is registered for `' .. (filetype ~= "" and filetype or 'this buffer') .. '`.',
        "",
        'Use <leader>dc once a DAP adapter/configuration has been added for this project.',
        'Project-local configs can live in .vscode/launch.json or .nvim/dap.lua.',
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

    dbg.dap.goto_current_debug_location = function()
      local session = dap.session()
      if not session then
        vim.notify('No active debug session', vim.log.levels.WARN)
        return
      end

      local frame = session.current_frame
      if not frame or not frame.source or not frame.source.path then
        vim.notify('No paused debug location available', vim.log.levels.WARN)
        return
      end

      vim.cmd('edit ' .. vim.fn.fnameescape(frame.source.path))
      vim.api.nvim_win_set_cursor(0, { frame.line or 1, 0 })
      vim.cmd('normal! zz')
    end

    keymapd('<leader>dc', 'Debug: Continue', function()
      if dbg.vscode.run_project_debug_config then
        dbg.vscode.run_project_debug_config()
      elseif dap.session() then
        dap.continue()
      end
    end)
    keymapd('<leader>dr', 'Debug: Run without debugging', function()
      if dbg.vscode.run_project_debug_config then
        dbg.vscode.run_project_debug_config(true)
      end
    end)
    -- keymapd('<leader>db', 'Debug: Toggle breakpoint', function() dap.toggle_breakpoint() end)
    keymapd('<leader>dn', 'Debug: Step over', function() dap.step_over() end)
    keymapd('<leader>di', 'Debug: Step into', function() dap.step_into() end)
    keymapd('<leader>dO', 'Debug: Step out', function() dap.step_out() end)
    keymapd('<leader>dx', 'Debug: Terminate/disconnect', function() if dap.session() then dap.terminate() end end)
    keymapd('<leader>do', 'Debug: Show task output', function()
      vim.cmd('DapTaskOutput')
    end)
    keymapd('<leader>dR', 'Debug: Recent task runs', function()
      vim.cmd('DapTaskRuns')
    end)
    keymapd('<leader>dK', 'Debug: Cancel running tasks', function()
      vim.cmd('DapCancelTask')
    end)
    keymapd('<leader>dg', 'Debug: Show guidance', dbg.dap.show_debug_guidance)
    keymapd('<leader>dG', 'Debug: Go to current location', dbg.dap.goto_current_debug_location)
    keymapd('<leader>dC', 'Debug: Create project config', dbg.dap.create_project_debug_config)
  '';
in
{
  inherit lua name;
}
