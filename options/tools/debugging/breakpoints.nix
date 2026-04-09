{ ... }:

let
  name = "tools.debugging";

  lua = /* lua */ ''
    local dbg = _G.nixvim_debugging
    local dap = require('dap')
    local dap_breakpoints = require('dap.breakpoints')

    wk.add({
      { '<leader>dB', group = 'Debug breakpoints', desc = 'Manage debug breakpoints' },
    })

    dbg.breakpoints.detect_project_root = function(bufnr)
      return dbg.helpers.detect_project_root(bufnr, {
        '.nvim/dap.lua',
        '.vscode/launch.json',
        '.vscode/tasks.json',
        '.nvim/dap-breakpoints.json',
      })
    end

    dbg.breakpoints.get_breakpoint_file = function(root)
      return root .. '/.nvim/dap-breakpoints.json'
    end

    dbg.breakpoints.make_relative = function(root, path)
      local normalized_root = vim.fs.normalize(root)
      local normalized_path = vim.fs.normalize(path)
      local prefix = normalized_root .. '/'
      if normalized_path:sub(1, #prefix) == prefix then
        return normalized_path:sub(#prefix + 1)
      end
    end

    dbg.breakpoints.collect_project_breakpoints = function(root)
      local result = {}
      for bufnr, file_breakpoints in pairs(dap_breakpoints.get()) do
        local relative_path = dbg.breakpoints.make_relative(root, vim.api.nvim_buf_get_name(bufnr))
        if relative_path then
          for _, breakpoint in ipairs(file_breakpoints) do
            table.insert(result, {
              path = relative_path,
              line = breakpoint.line,
              condition = breakpoint.condition,
              hitCondition = breakpoint.hitCondition,
              logMessage = breakpoint.logMessage,
            })
          end
        end
      end

      table.sort(result, function(left, right)
        if left.path == right.path then
          return left.line < right.line
        end
        return left.path < right.path
      end)
      return result
    end

    dbg.breakpoints.write_project_breakpoints = function(root)
      local breakpoints = dbg.breakpoints.collect_project_breakpoints(root)
      local breakpoint_file = dbg.breakpoints.get_breakpoint_file(root)
      if #breakpoints == 0 then
        if vim.fn.filereadable(breakpoint_file) == 1 then
          vim.fn.delete(breakpoint_file)
        end
        return
      end

      vim.fn.mkdir(vim.fs.dirname(breakpoint_file), 'p')
      vim.fn.writefile(vim.split(vim.json.encode({ version = 1, breakpoints = breakpoints }), '\n', { plain = true }), breakpoint_file)
    end

    dbg.breakpoints.persist_current_project_breakpoints = function(bufnr)
      local root = dbg.breakpoints.detect_project_root(bufnr or vim.api.nvim_get_current_buf())
      if root then
        dbg.breakpoints.write_project_breakpoints(root)
      end
    end

    dbg.breakpoints.load_project_breakpoints = function(bufnr, force_reload)
      local root = dbg.breakpoints.detect_project_root(bufnr or vim.api.nvim_get_current_buf())
      if not root then
        return
      end

      local breakpoint_file = dbg.breakpoints.get_breakpoint_file(root)
      if vim.fn.filereadable(breakpoint_file) ~= 1 then
        return
      end

      local current_signature = dbg.helpers.build_cache_key(breakpoint_file)
      local cached = dbg.state.breakpoint_cache[breakpoint_file]
      local decoded = cached and cached.decoded or nil

      if force_reload or not cached or cached.signature ~= current_signature then
        local ok
        ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(breakpoint_file), '\n'))
        if not ok or type(decoded) ~= 'table' or type(decoded.breakpoints) ~= 'table' then
          dprint('Failed to decode breakpoint file: ' .. breakpoint_file)
          return
        end
        dbg.state.breakpoint_cache[breakpoint_file] = {
          signature = current_signature,
          decoded = decoded,
          loaded_buffers = {},
        }
        cached = dbg.state.breakpoint_cache[breakpoint_file]
      end

      cached.loaded_buffers = cached.loaded_buffers or {}
      if not force_reload and cached.loaded_buffers.__all__ then
        return
      end

      for _, breakpoint in ipairs(decoded.breakpoints) do
        if type(breakpoint.path) == 'string' and type(breakpoint.line) == 'number' then
          local absolute_path = vim.fs.normalize(root .. '/' .. breakpoint.path)
          local bp_bufnr = vim.fn.bufadd(absolute_path)
          vim.fn.bufload(bp_bufnr)
          if breakpoint.line <= vim.api.nvim_buf_line_count(bp_bufnr) then
            dap_breakpoints.set({
              condition = breakpoint.condition,
              hit_condition = breakpoint.hitCondition,
              log_message = breakpoint.logMessage,
            }, bp_bufnr, breakpoint.line)
          end
        end
      end

      cached.loaded_buffers.__all__ = true
    end

    _G.load_project_breakpoints_for_project = dbg.breakpoints.load_project_breakpoints

    if not dbg.state.breakpoint_wrapped then
      dbg.state.breakpoint_wrapped = true

      local original_toggle_breakpoint = dap.toggle_breakpoint
      dap.toggle_breakpoint = function(...)
        original_toggle_breakpoint(...)
        dbg.breakpoints.persist_current_project_breakpoints()
      end

      local original_set_breakpoint = dap.set_breakpoint
      dap.set_breakpoint = function(...)
        original_set_breakpoint(...)
        dbg.breakpoints.persist_current_project_breakpoints()
      end

      local original_clear_breakpoints = dap.clear_breakpoints
      dap.clear_breakpoints = function(...)
        local roots = {}
        for bufnr, _ in pairs(dap_breakpoints.get()) do
          local root = dbg.breakpoints.detect_project_root(bufnr)
          if root then
            roots[root] = true
          end
        end
        original_clear_breakpoints(...)
        for root, _ in pairs(roots) do
          dbg.breakpoints.write_project_breakpoints(root)
        end
      end
    end

    dbg.breakpoints.get_project_breakpoint_items = function(bufnr)
      local root = dbg.breakpoints.detect_project_root(bufnr or vim.api.nvim_get_current_buf())
      if not root then
        return {}, nil
      end

      local items = {}
      for _, breakpoint in ipairs(dbg.breakpoints.collect_project_breakpoints(root)) do
        local suffix = breakpoint.condition or breakpoint.logMessage or breakpoint.hitCondition
        table.insert(items, {
          file = vim.fs.normalize(root .. '/' .. breakpoint.path),
          line = breakpoint.line,
          text = string.format('%s:%d', breakpoint.path, breakpoint.line) .. (suffix and ('  ' .. suffix) or ""),
        })
      end
      return items, root
    end

    dbg.breakpoints.open_breakpoint_item = function(item)
      if item and item.file then
        vim.cmd('edit ' .. vim.fn.fnameescape(item.file))
        vim.api.nvim_win_set_cursor(0, { item.line or 1, 0 })
        vim.cmd('normal! zz')
      end
    end

    dbg.breakpoints.pick_project_breakpoint = function()
      local items = dbg.breakpoints.get_project_breakpoint_items(vim.api.nvim_get_current_buf())
      if #items == 0 then
        vim.notify('No project breakpoints found', vim.log.levels.INFO)
        return
      end

      local has_snacks, snacks = pcall(require, 'snacks')
      if has_snacks and snacks.picker then
        snacks.picker.pick({
          source = 'dap-breakpoints',
          items = items,
          layout = 'vscode',
          format = 'text',
          title = 'Debug breakpoints',
          confirm = function(picker, item)
            picker:close()
            dbg.breakpoints.open_breakpoint_item(item)
          end,
        })
        return
      end

      vim.ui.select(items, {
        prompt = 'Debug breakpoints',
        format_item = function(item)
          return item.text
        end,
      }, dbg.breakpoints.open_breakpoint_item)
    end

    dbg.breakpoints.clear_project_breakpoints = function()
      dap.clear_breakpoints()
      local root = dbg.breakpoints.detect_project_root(vim.api.nvim_get_current_buf())
      if root then
        local breakpoint_file = dbg.breakpoints.get_breakpoint_file(root)
        if vim.fn.filereadable(breakpoint_file) == 1 then
          vim.fn.delete(breakpoint_file)
        end
      end
      vim.notify('Cleared all debug breakpoints', vim.log.levels.INFO)
    end

    vim.api.nvim_create_user_command('DapLoadProjectBreakpoints', function()
      dbg.breakpoints.load_project_breakpoints(vim.api.nvim_get_current_buf(), true)
    end, { desc = 'Reload project debug breakpoints' })

    -- This should load the breakpoints for the current project 
    --    immediately when system is opened
    dbg.breakpoints.load_project_breakpoints(nil, true)

    keymapd('<leader>dBB', 'Debug breakpoints: Picker', dbg.breakpoints.pick_project_breakpoint)
    keymapd('<leader>dBC', 'Debug breakpoints: Clear all', dbg.breakpoints.clear_project_breakpoints)
    keymapd('<leader>db', 'Debug: Toggle breakpoint', function() 
      dap.toggle_breakpoint() 
    end)
  '';
in
{
  inherit lua name;
}
