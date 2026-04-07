{ ... }:

let
  name = "tools.debugging";

  lua = /* lua */ ''
    wk.add({
      { '<leader>dB', group = 'Debug breakpoints', desc = 'Manage debug breakpoints' },
    })

    local dap = require('dap')
    local dap_breakpoints = require('dap.breakpoints')

    local function get_root_markers()
      local markers = { '.git', '.nvim/dap.lua', '.nvim/dap-breakpoints.json' }
      local seen = {
        ['.git'] = true,
        ['.nvim/dap.lua'] = true,
        ['.nvim/dap-breakpoints.json'] = true,
      }

      for _, spec in pairs(_G.debug_language_registry or {}) do
        for _, marker in ipairs(spec.root_markers or {}) do
          if not seen[marker] then
            table.insert(markers, marker)
            seen[marker] = true
          end
        end
      end

      return markers
    end

    local function detect_breakpoint_root(bufnr)
      local buffer_name = vim.api.nvim_buf_get_name(bufnr)
      local start_path = buffer_name ~= "" and vim.fs.dirname(buffer_name) or vim.uv.cwd()
      local found = vim.fs.find(get_root_markers(), {
        path = start_path,
        upward = true,
        stop = vim.uv.os_homedir(),
      })[1]

      if not found then
        return nil
      end

      local normalized = vim.fs.normalize(found)
      if normalized:match('/%.nvim/dap%.lua$') or normalized:match('/%.nvim/dap%-breakpoints%.json$') then
        return vim.fs.dirname(vim.fs.dirname(normalized))
      end

      return vim.fs.dirname(normalized)
    end

    local function get_breakpoint_file(root)
      return root .. '/.nvim/dap-breakpoints.json'
    end

    local function build_cache_key(path)
      local stat = vim.uv.fs_stat(path)
      if not stat or not stat.mtime then
        return nil
      end

      return tostring(stat.mtime.sec) .. ':' .. tostring(stat.mtime.nsec or 0)
    end

    local function normalize_path(path)
      return vim.fs.normalize(path)
    end

    local function make_relative(root, path)
      local normalized_root = normalize_path(root)
      local normalized_path = normalize_path(path)
      local prefix = normalized_root .. '/'
      if normalized_path:sub(1, #prefix) == prefix then
        return normalized_path:sub(#prefix + 1)
      end
      return nil
    end

    local function collect_project_breakpoints(root)
      local result = {}
      local all_breakpoints = dap_breakpoints.get()

      for bufnr, file_breakpoints in pairs(all_breakpoints) do
        local file_path = vim.api.nvim_buf_get_name(bufnr)
        local relative_path = make_relative(root, file_path)
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

    local function write_project_breakpoints(root)
      local breakpoints = collect_project_breakpoints(root)
      local breakpoint_file = get_breakpoint_file(root)

      if #breakpoints == 0 then
        if vim.fn.filereadable(breakpoint_file) == 1 then
          vim.fn.delete(breakpoint_file)
        end
        return
      end

      vim.fn.mkdir(vim.fs.dirname(breakpoint_file), 'p')
      local encoded = vim.json.encode({
        version = 1,
        breakpoints = breakpoints,
      })
      vim.fn.writefile(vim.split(encoded, '\n', { plain = true }), breakpoint_file)
    end

    local function persist_current_project_breakpoints(bufnr)
      local root = detect_breakpoint_root(bufnr or vim.api.nvim_get_current_buf())
      if not root then
        return
      end

      write_project_breakpoints(root)
    end

    local function load_project_breakpoints(bufnr, force_reload)
      local target_bufnr = bufnr or vim.api.nvim_get_current_buf()
      local root = detect_breakpoint_root(target_bufnr)
      if not root then
        return
      end

      local breakpoint_file = get_breakpoint_file(root)
      if vim.fn.filereadable(breakpoint_file) ~= 1 then
        return
      end

      _G._nixvim_breakpoint_cache = _G._nixvim_breakpoint_cache or {}
      local cache = _G._nixvim_breakpoint_cache
      local current_signature = build_cache_key(breakpoint_file)
      local cached = cache[breakpoint_file]
      local decoded = cached and cached.decoded or nil

      if force_reload or not cached or cached.signature ~= current_signature then
        local lines = vim.fn.readfile(breakpoint_file)
        local ok
        ok, decoded = pcall(vim.json.decode, table.concat(lines, '\n'))
        if ok and type(decoded) == 'table' and type(decoded.breakpoints) == 'table' then
          cache[breakpoint_file] = {
            signature = current_signature,
            decoded = decoded,
            loaded_buffers = {},
          }
          cached = cache[breakpoint_file]
        else
          dprint('Failed to decode breakpoint file: ' .. breakpoint_file)
          return
        end
      end

      if not decoded or type(decoded) ~= 'table' or type(decoded.breakpoints) ~= 'table' then
        dprint('Failed to decode breakpoint file: ' .. breakpoint_file)
        return
      end

      cached.loaded_buffers = cached.loaded_buffers or {}
      if not force_reload and cached.loaded_buffers['__all__'] then
        return
      end

      for _, breakpoint in ipairs(decoded.breakpoints) do
        if type(breakpoint.path) == 'string' and type(breakpoint.line) == 'number' then
          local absolute_path = normalize_path(root .. '/' .. breakpoint.path)
          local bp_bufnr = vim.fn.bufadd(absolute_path)
          vim.fn.bufload(bp_bufnr)
          local line_count = vim.api.nvim_buf_line_count(bp_bufnr)
          if breakpoint.line <= line_count then
            dap_breakpoints.set({
              condition = breakpoint.condition,
              hit_condition = breakpoint.hitCondition,
              log_message = breakpoint.logMessage,
            }, bp_bufnr, breakpoint.line)
          end
        end
      end

      cached.loaded_buffers['__all__'] = true
    end

    _G.load_project_breakpoints_for_project = load_project_breakpoints

    if not _G._nixvim_breakpoint_wrapped then
      _G._nixvim_breakpoint_wrapped = true

      local original_toggle_breakpoint = dap.toggle_breakpoint
      dap.toggle_breakpoint = function(...)
        original_toggle_breakpoint(...)
        persist_current_project_breakpoints()
      end

      local original_set_breakpoint = dap.set_breakpoint
      dap.set_breakpoint = function(...)
        original_set_breakpoint(...)
        persist_current_project_breakpoints()
      end

      local original_clear_breakpoints = dap.clear_breakpoints
      dap.clear_breakpoints = function(...)
        local roots = {}
        for bufnr, _ in pairs(dap_breakpoints.get()) do
          local root = detect_breakpoint_root(bufnr)
          if root then
            roots[root] = true
          end
        end

        original_clear_breakpoints(...)

        for root, _ in pairs(roots) do
          write_project_breakpoints(root)
        end
      end
    end

    local function get_project_breakpoint_items(bufnr)
      local root = detect_breakpoint_root(bufnr or vim.api.nvim_get_current_buf())
      if not root then
        return {}, nil
      end

      local items = {}
      for _, breakpoint in ipairs(collect_project_breakpoints(root)) do
        local suffix = breakpoint.condition or breakpoint.logMessage or breakpoint.hitCondition
        table.insert(items, {
          file = normalize_path(root .. '/' .. breakpoint.path),
          line = breakpoint.line,
          text = string.format('%s:%d', breakpoint.path, breakpoint.line) .. (suffix and ('  ' .. suffix) or ""),
        })
      end

      return items, root
    end

    local function open_breakpoint_item(item)
      if not item or not item.file then
        return
      end

      vim.cmd('edit ' .. vim.fn.fnameescape(item.file))
      vim.api.nvim_win_set_cursor(0, { item.line or 1, 0 })
      vim.cmd('normal! zz')
    end

    local function pick_project_breakpoint()
      local items = get_project_breakpoint_items(vim.api.nvim_get_current_buf())
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
            open_breakpoint_item(item)
          end,
        })
        return
      end

      vim.ui.select(items, {
        prompt = 'Debug breakpoints',
        format_item = function(item)
          return item.text
        end,
      }, open_breakpoint_item)
    end

    local function clear_project_breakpoints()
      dap.clear_breakpoints()

      local root = detect_breakpoint_root(vim.api.nvim_get_current_buf())
      if root then
        local breakpoint_file = get_breakpoint_file(root)
        if vim.fn.filereadable(breakpoint_file) == 1 then
          vim.fn.delete(breakpoint_file)
        end
      end

      vim.notify('Cleared all debug breakpoints', vim.log.levels.INFO)
    end

    vim.api.nvim_create_user_command('DapLoadProjectBreakpoints', function()
      load_project_breakpoints(vim.api.nvim_get_current_buf(), true)
    end, { desc = 'Reload project debug breakpoints' })

    keymapd('<leader>dBB', 'Debug breakpoints: Picker', pick_project_breakpoint)
    keymapd('<leader>dBC', 'Debug breakpoints: Clear all', clear_project_breakpoints)
  '';
in
{
  inherit lua name;
}
