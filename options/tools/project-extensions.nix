{ ... }:

let
  name = "tools";

  lua = /* lua */ ''
    wk.add({
      { '<leader>p', group = 'Project', desc = 'Project actions' },
    })

    local function find_project_extension_file(bufnr)
      local buffer_name = vim.api.nvim_buf_get_name(bufnr)
      local start_path = buffer_name ~= "" and vim.fs.dirname(buffer_name) or vim.uv.cwd()

      return vim.fs.find('.nvim/project.lua', {
        path = start_path,
        upward = true,
        stop = vim.uv.os_homedir(),
      })[1]
    end

    local function build_cache_key(path)
      local stat = vim.uv.fs_stat(path)
      if not stat or not stat.mtime then
        return nil
      end

      return tostring(stat.mtime.sec) .. ':' .. tostring(stat.mtime.nsec or 0)
    end

    local function detect_project_root(bufnr)
      local project_file = find_project_extension_file(bufnr)
      if project_file then
        return vim.fs.dirname(vim.fs.dirname(project_file))
      end

      local buffer_name = vim.api.nvim_buf_get_name(bufnr)
      local start_path = buffer_name ~= "" and vim.fs.dirname(buffer_name) or vim.uv.cwd()
      local found = vim.fs.find('.git', {
        path = start_path,
        upward = true,
        stop = vim.uv.os_homedir(),
      })[1]

      if found then
        return vim.fs.dirname(found)
      end

      return vim.uv.cwd()
    end

    local function project_template()
      return table.concat({
        'return function(ctx)',
        '  local root = ctx.root',
        '  local bufnr = ctx.bufnr',
        '  local filetype = ctx.filetype',
        "",
        'end',
      }, '\n')
    end

    local function load_project_extension(bufnr, force_reload)
      local target_bufnr = bufnr or vim.api.nvim_get_current_buf()
      local project_file = find_project_extension_file(target_bufnr)
      if not project_file then
        return
      end

      _G._nixvim_project_extension_cache = _G._nixvim_project_extension_cache or {}
      local cache = _G._nixvim_project_extension_cache
      local signature = build_cache_key(project_file)
      if not force_reload and cache[project_file] == signature then
        return
      end

      local chunk, err = loadfile(project_file)
      if not chunk then
        dprint('Failed to parse project extension (' .. project_file .. '): ' .. tostring(err))
        return
      end

      local ok, result = pcall(chunk)
      if not ok then
        dprint('Failed to load project extension (' .. project_file .. '): ' .. tostring(result))
        return
      end

      if type(result) == 'function' then
        local project_root = vim.fs.dirname(vim.fs.dirname(project_file))
        local project_ok, project_err = pcall(result, {
          root = project_root,
          bufnr = target_bufnr,
          filetype = vim.bo[target_bufnr].filetype,
        })
        if not project_ok then
          dprint('Failed to run project extension (' .. project_file .. '): ' .. tostring(project_err))
          return
        end
      end

      cache[project_file] = signature
    end

    local function edit_project_extension()
      local bufnr = vim.api.nvim_get_current_buf()
      local root = detect_project_root(bufnr)
      local project_file = root .. '/.nvim/project.lua'

      vim.fn.mkdir(vim.fs.dirname(project_file), 'p')

      if vim.fn.filereadable(project_file) ~= 1 then
        vim.fn.writefile(vim.split(project_template(), '\n', { plain = true }), project_file)
      end

      vim.cmd('edit ' .. vim.fn.fnameescape(project_file))
    end

    vim.api.nvim_create_user_command('ProjectExtensionsReload', function()
      load_project_extension(vim.api.nvim_get_current_buf(), true)
    end, { desc = 'Reload .nvim/project.lua for current project' })

    vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
      callback = function(args)
        local buftype = vim.api.nvim_get_option_value('buftype', { buf = args.buf })
        if buftype ~= "" then
          return
        end
        load_project_extension(args.buf, false)
      end,
      desc = 'Load project extension on buffer open',
    })

    keymapd('<leader>pC', 'Project: Edit config', edit_project_extension)
    keymapd('<leader>pr', 'Project: Reload config', function()
      load_project_extension(vim.api.nvim_get_current_buf(), true)
    end)
  '';
in
{
  inherit lua name;
}
