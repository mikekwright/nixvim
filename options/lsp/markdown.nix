{pkgs, ...}: let
  name = "lsp.markdown";

  mermaidAscii = pkgs.buildGoModule rec {
    pname = "mermaid-ascii";
    version = "1.1.0";

    src = pkgs.fetchFromGitHub {
      owner = "AlexanderGrooff";
      repo = "mermaid-ascii";
      rev = version;
      hash = "sha256-SoUMaCFhJe0g2vrZJ77EsIojqYX3TuQRCtWl7mzY2JQ=";
    };

    vendorHash = "sha256-aB9sbTtlHbptM2995jizGFtSmEIg3i8zWkXz1zzbIek=";
  };

  lua = /*lua*/ ''
    vim.g.mkdp_auto_start = 0
    vim.g.mkdp_auto_close = 1
    vim.g.mkdp_combine_preview = 1
    vim.g.mkdp_combine_preview_auto_refresh = 1
    vim.g.mkdp_filetypes = { "markdown" }

    local markdownPlugin = require('render-markdown')
    markdownPlugin.setup({})

    local mermaid_ascii_bin = "${mermaidAscii}/bin/mermaid-ascii"
    local mermaid_preview_ns = vim.api.nvim_create_namespace("markdown-mermaid-ascii-preview")
    local mermaid_preview_group = vim.api.nvim_create_augroup("MarkdownMermaidAsciiPreview", { clear = true })
    local mermaid_preview_state = {
      buf = nil,
      mode = nil,
      source_buf = nil,
      layout = "horizontal",
      split_cmd = "botright split",
      target_extmark = nil,
      selection_start_extmark = nil,
      selection_end_extmark = nil,
      refresh_generation = 0,
    }

    local function split_lines(text)
      if text == nil or text == "" then
        return { "" }
      end

      if text:sub(-1) == "\n" then
        text = text:sub(1, -2)
      end

      return vim.split(text, "\n", { plain = true })
    end

    local function extract_lines(bufnr, start_line, end_line)
      return vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
    end

    local function has_content(lines)
      return vim.trim(table.concat(lines, "\n")) ~= ""
    end

    local function append_fenced_block(output, language, lines)
      table.insert(output, string.format("```%s", language))
      vim.list_extend(output, lines)
      table.insert(output, "```")
    end

    local function clear_extmark(bufnr, extmark_id)
      if bufnr == nil or extmark_id == nil or not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end

      pcall(vim.api.nvim_buf_del_extmark, bufnr, mermaid_preview_ns, extmark_id)
    end

    local function clear_target_tracking(bufnr)
      clear_extmark(bufnr or mermaid_preview_state.source_buf, mermaid_preview_state.target_extmark)
      mermaid_preview_state.target_extmark = nil
    end

    local function clear_selection_tracking(bufnr)
      local tracking_buf = bufnr or mermaid_preview_state.source_buf
      clear_extmark(tracking_buf, mermaid_preview_state.selection_start_extmark)
      clear_extmark(tracking_buf, mermaid_preview_state.selection_end_extmark)
      mermaid_preview_state.selection_start_extmark = nil
      mermaid_preview_state.selection_end_extmark = nil
    end

    local function build_preview_document(title, sections)
      local output = {
        "# Mermaid ASCII Preview",
        "",
        title,
      }

      for _, section in ipairs(sections) do
        table.insert(output, "")
        table.insert(output, string.format("## %s", section.heading))
        table.insert(output, "")
        table.insert(output, "### Mermaid Source")
        table.insert(output, "")
        append_fenced_block(output, "mermaid", section.source_lines)
        table.insert(output, "")
        table.insert(output, "### Rendered ASCII")
        table.insert(output, "")
        append_fenced_block(output, "text", section.rendered_lines)
      end

      return output
    end

    local function get_mermaid_blocks(bufnr)
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local blocks = {}
      local active_block = nil

      for line_number, line in ipairs(lines) do
        if active_block == nil then
          local fence, language = line:match("^([`~][`~][`~]+)%s*(%S+)%s*$")
          if fence ~= nil and language ~= nil and language:lower() == "mermaid" then
            active_block = {
              fence = fence,
              start_line = line_number,
              lines = {},
            }
          end
        else
          local closing_fence = line:match("^([`~][`~][`~]+)%s*$")
          if closing_fence ~= nil
            and closing_fence:sub(1, 1) == active_block.fence:sub(1, 1)
            and #closing_fence >= #active_block.fence
          then
            table.insert(blocks, {
              start_line = active_block.start_line,
              end_line = line_number,
              content = table.concat(active_block.lines, "\n"),
            })
            active_block = nil
          else
            table.insert(active_block.lines, line)
          end
        end
      end

      return blocks
    end

    local function get_mermaid_block_for_line(bufnr, cursor_line)
      for _, block in ipairs(get_mermaid_blocks(bufnr)) do
        if cursor_line >= block.start_line and cursor_line <= block.end_line then
          return block
        end
      end

      return nil
    end

    local function render_mermaid_block(diagram)
      local result = vim.system({ mermaid_ascii_bin, "--ascii" }, {
        stdin = diagram,
        text = true,
      }):wait()

      if result.code ~= 0 then
        local stderr = result.stderr or "Unknown mermaid-ascii error"
        error(stderr)
      end

      return result.stdout or ""
    end

    local refresh_mermaid_preview

    local function get_visual_line_range()
      local mode = vim.fn.mode()
      local start_line
      local end_line

      if mode == "v" or mode == "V" or mode == "\022" then
        start_line = vim.fn.line("v")
        end_line = vim.fn.line(".")
      else
        start_line = vim.fn.getpos("'<")[2]
        end_line = vim.fn.getpos("'>")[2]
      end

      if start_line == 0 or end_line == 0 then
        return nil
      end

      if start_line > end_line then
        start_line, end_line = end_line, start_line
      end

      return start_line, end_line
    end

    local function get_preview_target_line()
      if mermaid_preview_state.source_buf == nil or mermaid_preview_state.target_extmark == nil then
        return nil
      end

      if not vim.api.nvim_buf_is_valid(mermaid_preview_state.source_buf) then
        return nil
      end

      local extmark = vim.api.nvim_buf_get_extmark_by_id(
        mermaid_preview_state.source_buf,
        mermaid_preview_ns,
        mermaid_preview_state.target_extmark,
        {}
      )

      if vim.tbl_isempty(extmark) then
        return nil
      end

      return extmark[1] + 1
    end

    local function get_preview_selection_range()
      if mermaid_preview_state.source_buf == nil then
        return nil
      end

      if mermaid_preview_state.selection_start_extmark == nil or mermaid_preview_state.selection_end_extmark == nil then
        return nil
      end

      if not vim.api.nvim_buf_is_valid(mermaid_preview_state.source_buf) then
        return nil
      end

      local start_extmark = vim.api.nvim_buf_get_extmark_by_id(
        mermaid_preview_state.source_buf,
        mermaid_preview_ns,
        mermaid_preview_state.selection_start_extmark,
        {}
      )
      local end_extmark = vim.api.nvim_buf_get_extmark_by_id(
        mermaid_preview_state.source_buf,
        mermaid_preview_ns,
        mermaid_preview_state.selection_end_extmark,
        {}
      )

      if vim.tbl_isempty(start_extmark) or vim.tbl_isempty(end_extmark) then
        return nil
      end

      local start_line = start_extmark[1] + 1
      local end_line = end_extmark[1] + 1

      if start_line > end_line then
        start_line, end_line = end_line, start_line
      end

      return start_line, end_line
    end

    local function schedule_preview_refresh()
      if mermaid_preview_state.source_buf == nil or mermaid_preview_state.mode == nil then
        return
      end

      local source_buf = mermaid_preview_state.source_buf
      local mode = mermaid_preview_state.mode
      local layout = mermaid_preview_state.layout
      local split_cmd = mermaid_preview_state.split_cmd

      mermaid_preview_state.refresh_generation = mermaid_preview_state.refresh_generation + 1
      local refresh_generation = mermaid_preview_state.refresh_generation

      vim.defer_fn(function()
        if refresh_generation ~= mermaid_preview_state.refresh_generation then
          return
        end

        if source_buf == nil or not vim.api.nvim_buf_is_valid(source_buf) then
          return
        end

        if mermaid_preview_state.source_buf ~= source_buf or mermaid_preview_state.mode ~= mode then
          return
        end

        if mermaid_preview_state.buf == nil or find_window_for_buffer(mermaid_preview_state.buf) == nil then
          return
        end

        refresh_mermaid_preview({
          source_buf = source_buf,
          mode = mode,
          layout = layout,
          split_cmd = split_cmd,
          focus = false,
          notify = false,
        })
      end, 150)
    end

    local function ensure_preview_buffer()
      if mermaid_preview_state.buf == nil or not vim.api.nvim_buf_is_valid(mermaid_preview_state.buf) then
        mermaid_preview_state.buf = vim.api.nvim_create_buf(false, true)
        pcall(vim.api.nvim_buf_set_name, mermaid_preview_state.buf, "Mermaid-ASCII-Preview")
        vim.api.nvim_set_option_value("buftype", "nofile", { buf = mermaid_preview_state.buf })
        vim.api.nvim_set_option_value("bufhidden", "hide", { buf = mermaid_preview_state.buf })
        vim.api.nvim_set_option_value("swapfile", false, { buf = mermaid_preview_state.buf })
        vim.api.nvim_set_option_value("buflisted", false, { buf = mermaid_preview_state.buf })
        vim.keymap.set("n", "q", "<cmd>close<CR>", {
          buffer = mermaid_preview_state.buf,
          silent = true,
          desc = "Close Mermaid ASCII preview",
        })
        vim.keymap.set("n", "r", function()
          refresh_mermaid_preview({ notify = true })
        end, {
          buffer = mermaid_preview_state.buf,
          silent = true,
          desc = "Refresh Mermaid ASCII preview",
        })
      end

      return mermaid_preview_state.buf
    end

    local function build_float_config()
      local ui = vim.api.nvim_list_uis()[1]
      local ui_width = ui and ui.width or vim.o.columns
      local ui_height = ui and ui.height or vim.o.lines
      local width = math.max(80, math.floor(ui_width * 0.75))
      local height = math.max(24, math.floor(ui_height * 0.75))

      width = math.min(width, math.max(40, ui_width - 4))
      height = math.min(height, math.max(12, ui_height - 4))

      return {
        relative = "editor",
        style = "minimal",
        border = "rounded",
        title = " Mermaid ASCII Preview ",
        title_pos = "center",
        width = width,
        height = height,
        row = math.floor((ui_height - height) / 2),
        col = math.floor((ui_width - width) / 2),
      }
    end

    local function configure_preview_window(preview_window)
      vim.api.nvim_set_option_value("wrap", false, { win = preview_window })
      vim.api.nvim_set_option_value("number", false, { win = preview_window })
      vim.api.nvim_set_option_value("relativenumber", false, { win = preview_window })
      vim.api.nvim_set_option_value("cursorline", false, { win = preview_window })
      vim.api.nvim_set_option_value("signcolumn", "no", { win = preview_window })
    end

    local function open_preview_buffer(title, content_lines, opts)
      opts = opts or {}
      local preview_buf = ensure_preview_buffer()
      local layout = opts.layout or mermaid_preview_state.layout
      local split_cmd = opts.split_cmd or mermaid_preview_state.split_cmd
      local preview_window = find_window_for_buffer(preview_buf)
      local focus = opts.focus ~= false
      local current_window = vim.api.nvim_get_current_win()

      if opts.reopen and preview_window ~= nil then
        vim.api.nvim_win_close(preview_window, true)
        preview_window = nil
      end

      vim.api.nvim_set_option_value("modifiable", true, { buf = preview_buf })
      vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, content_lines)
      vim.api.nvim_set_option_value("modifiable", false, { buf = preview_buf })
      vim.api.nvim_set_option_value("filetype", "markdown", { buf = preview_buf })

      if preview_window == nil then
        if layout == "float" then
          preview_window = vim.api.nvim_open_win(preview_buf, focus, build_float_config())
        else
          vim.cmd(split_cmd)
          preview_window = vim.api.nvim_get_current_win()
          vim.api.nvim_win_set_buf(preview_window, preview_buf)
        end
      elseif focus then
        vim.api.nvim_set_current_win(preview_window)
      end

      if layout ~= "float" and not focus and vim.api.nvim_win_is_valid(current_window) then
        vim.api.nvim_set_current_win(current_window)
      end

      configure_preview_window(preview_window)
      vim.api.nvim_win_set_cursor(preview_window, { 1, 0 })
      vim.api.nvim_set_option_value("modified", false, { buf = preview_buf })

      if opts.notify ~= false then
        vim.notify(title, vim.log.levels.INFO)
      end
    end

    local function ensure_markdown_buffer()
      if vim.bo.filetype ~= "markdown" then
        vim.notify("Mermaid ASCII preview only works in Markdown buffers", vim.log.levels.WARN)
        return false
      end

      return true
    end

    local function set_preview_source(source_buf)
      local previous_source_buf = mermaid_preview_state.source_buf

      if previous_source_buf ~= nil and previous_source_buf ~= source_buf then
        clear_target_tracking(previous_source_buf)
        clear_selection_tracking(previous_source_buf)
      end

      mermaid_preview_state.source_buf = source_buf

      vim.api.nvim_clear_autocmds({ group = mermaid_preview_group })
      vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost" }, {
        group = mermaid_preview_group,
        buffer = source_buf,
        callback = schedule_preview_refresh,
      })
      vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
        group = mermaid_preview_group,
        buffer = source_buf,
        callback = function()
          mermaid_preview_state.refresh_generation = mermaid_preview_state.refresh_generation + 1
          clear_target_tracking(source_buf)
          clear_selection_tracking(source_buf)
          mermaid_preview_state.source_buf = nil
          mermaid_preview_state.mode = nil
        end,
      })
    end

    local function set_preview_selection_range(source_buf, start_line, end_line)
      clear_selection_tracking(source_buf)
      mermaid_preview_state.selection_start_extmark = vim.api.nvim_buf_set_extmark(
        source_buf,
        mermaid_preview_ns,
        start_line - 1,
        0,
        { right_gravity = false }
      )
      mermaid_preview_state.selection_end_extmark = vim.api.nvim_buf_set_extmark(
        source_buf,
        mermaid_preview_ns,
        end_line - 1,
        0,
        { right_gravity = true }
      )
    end

    local function build_current_preview(source_buf, target_line)
      local block = get_mermaid_block_for_line(source_buf, target_line)

      if block == nil then
        return nil, "Move the cursor into a Mermaid fence to preview it", vim.log.levels.WARN
      end

      local ok, rendered = pcall(render_mermaid_block, block.content)
      if not ok then
        return nil, "Failed to render Mermaid block: " .. rendered, vim.log.levels.ERROR
      end

      return {
        title = string.format("Rendered Mermaid block from lines %d-%d", block.start_line, block.end_line),
        lines = build_preview_document(
          string.format("Current block from lines %d-%d", block.start_line, block.end_line),
          {
            {
              heading = string.format("Block %d-%d", block.start_line, block.end_line),
              source_lines = split_lines(block.content),
              rendered_lines = split_lines(rendered),
            },
          }
        ),
      }
    end

    local function build_all_preview(source_buf)
      local blocks = get_mermaid_blocks(source_buf)

      if vim.tbl_isempty(blocks) then
        return nil, "No Mermaid fences found in this Markdown buffer", vim.log.levels.WARN
      end

      local sections = {}

      for index, block in ipairs(blocks) do
        local ok, rendered = pcall(render_mermaid_block, block.content)
        if not ok then
          return nil, "Failed to render Mermaid block " .. index .. ": " .. rendered, vim.log.levels.ERROR
        end

        table.insert(sections, {
          heading = string.format("Block %d (lines %d-%d)", index, block.start_line, block.end_line),
          source_lines = split_lines(block.content),
          rendered_lines = split_lines(rendered),
        })
      end

      return {
        title = string.format("Rendered %d Mermaid blocks", #blocks),
        lines = build_preview_document(
          string.format("All Mermaid blocks from %s", vim.fn.fnamemodify(vim.api.nvim_buf_get_name(source_buf), ":t")),
          sections
        ),
      }
    end

    local function build_selection_preview(source_buf, start_line, end_line)
      local source_lines = extract_lines(source_buf, start_line, end_line)
      if not has_content(source_lines) then
        return nil, "Select Mermaid content before previewing it", vim.log.levels.WARN
      end

      local ok, rendered = pcall(render_mermaid_block, table.concat(source_lines, "\n"))
      if not ok then
        return nil, "Failed to render Mermaid selection: " .. rendered, vim.log.levels.ERROR
      end

      return {
        title = string.format("Rendered Mermaid selection from lines %d-%d", start_line, end_line),
        lines = build_preview_document(
          string.format("Selected Mermaid lines %d-%d", start_line, end_line),
          {
            {
              heading = string.format("Selection %d-%d", start_line, end_line),
              source_lines = source_lines,
              rendered_lines = split_lines(rendered),
            },
          }
        ),
      }
    end

    local function browser_preview_available()
      return vim.fn.exists(":MarkdownPreview") == 2 or vim.fn.exists(":MarkdownPreviewToggle") == 2
    end

    local function toggle_markdown_browser_preview()
      if not ensure_markdown_buffer() or vim.bo.buftype ~= "" then
        vim.notify("Browser Markdown preview only works in file-backed Markdown buffers", vim.log.levels.WARN)
        return
      end

      if not browser_preview_available() then
        vim.notify("markdown-preview.nvim is not available", vim.log.levels.ERROR)
        return
      end

      vim.cmd("MarkdownPreviewToggle")
    end

    refresh_mermaid_preview = function(opts)
      opts = opts or {}

      local source_buf = opts.source_buf or mermaid_preview_state.source_buf or vim.api.nvim_get_current_buf()
      if not vim.api.nvim_buf_is_valid(source_buf) then
        return
      end

      if vim.api.nvim_get_option_value("filetype", { buf = source_buf }) ~= "markdown" then
        if opts.notify ~= false then
          vim.notify("Mermaid ASCII preview only works in Markdown buffers", vim.log.levels.WARN)
        end
        return
      end

      local mode = opts.mode or mermaid_preview_state.mode or "current"
      local layout = opts.layout or mermaid_preview_state.layout or "horizontal"
      local split_cmd = opts.split_cmd or mermaid_preview_state.split_cmd or "botright split"
      local preview
      local message
      local level

      if mode == "current" then
        clear_selection_tracking(source_buf)
        local target_line = opts.target_line or get_preview_target_line()
        if target_line == nil then
          local source_window = find_window_for_buffer(source_buf)
          if source_window ~= nil then
            target_line = vim.api.nvim_win_get_cursor(source_window)[1]
          else
            target_line = 1
          end
        end

        preview, message, level = build_current_preview(source_buf, target_line)
        if preview ~= nil then
          clear_target_tracking(source_buf)
          mermaid_preview_state.target_extmark = vim.api.nvim_buf_set_extmark(
            source_buf,
            mermaid_preview_ns,
            target_line - 1,
            0,
            { id = mermaid_preview_state.target_extmark, right_gravity = false }
          )
        end
      elseif mode == "selection" then
        clear_target_tracking(source_buf)
        local start_line = opts.start_line
        local end_line = opts.end_line

        if start_line == nil or end_line == nil then
          start_line, end_line = get_preview_selection_range()
        end

        if start_line == nil or end_line == nil then
          preview, message, level = nil, "Select Mermaid content before previewing it", vim.log.levels.WARN
        else
          preview, message, level = build_selection_preview(source_buf, start_line, end_line)
          if preview ~= nil then
            set_preview_selection_range(source_buf, start_line, end_line)
          end
        end
      else
        preview, message, level = build_all_preview(source_buf)
        clear_target_tracking(source_buf)
        clear_selection_tracking(source_buf)
      end

      if preview == nil then
        if opts.notify ~= false then
          vim.notify(message, level)
        end
        return
      end

      mermaid_preview_state.mode = mode
      mermaid_preview_state.layout = layout
      mermaid_preview_state.split_cmd = split_cmd
      set_preview_source(source_buf)

      open_preview_buffer(
        preview.title,
        preview.lines,
        {
          layout = layout,
          split_cmd = split_cmd,
          focus = opts.focus,
          reopen = opts.reopen,
          notify = opts.notify,
        }
      )
    end

    local function preview_current_mermaid_block(opts)
      if not ensure_markdown_buffer() then
        return
      end

      opts = opts or {}
      local layout = opts.layout or "horizontal"
      refresh_mermaid_preview({
        source_buf = vim.api.nvim_get_current_buf(),
        mode = "current",
        layout = layout,
        split_cmd = opts.split_cmd or "botright split",
        target_line = vim.api.nvim_win_get_cursor(0)[1],
        focus = opts.focus,
        reopen = true,
        notify = true,
      })
    end

    local function preview_all_mermaid_blocks(opts)
      if not ensure_markdown_buffer() then
        return
      end

      opts = opts or {}
      local layout = opts.layout or "horizontal"
      refresh_mermaid_preview({
        source_buf = vim.api.nvim_get_current_buf(),
        mode = "all",
        layout = layout,
        split_cmd = opts.split_cmd or "botright split",
        focus = opts.focus,
        reopen = true,
        notify = true,
      })
    end

    local function preview_visual_mermaid_selection(opts)
      if not ensure_markdown_buffer() then
        return
      end

      opts = opts or {}
      local start_line = opts.line1 or opts.start_line
      local end_line = opts.line2 or opts.end_line

      if start_line == nil or end_line == nil then
        start_line, end_line = get_visual_line_range()
      end

      if start_line == nil or end_line == nil then
        vim.notify("Select Mermaid content before previewing it", vim.log.levels.WARN)
        return
      end

      local layout = opts.layout or "horizontal"
      refresh_mermaid_preview({
        source_buf = vim.api.nvim_get_current_buf(),
        mode = "selection",
        layout = layout,
        split_cmd = opts.split_cmd or "botright split",
        start_line = start_line,
        end_line = end_line,
        focus = opts.focus,
        reopen = true,
        notify = true,
      })
    end

    local function toggle_mermaid_preview_float()
      local source_buf = mermaid_preview_state.source_buf
      if source_buf == nil or not vim.api.nvim_buf_is_valid(source_buf) then
        if not ensure_markdown_buffer() then
          return
        end

        refresh_mermaid_preview({
          source_buf = vim.api.nvim_get_current_buf(),
          mode = "current",
          layout = "float",
          split_cmd = mermaid_preview_state.split_cmd,
          target_line = vim.api.nvim_win_get_cursor(0)[1],
          reopen = true,
          notify = true,
        })
        return
      end

      if mermaid_preview_state.layout == "float" then
        refresh_mermaid_preview({
          source_buf = source_buf,
          mode = mermaid_preview_state.mode or "current",
          layout = mermaid_preview_state.split_cmd == "botright vsplit" and "vertical" or "horizontal",
          split_cmd = mermaid_preview_state.split_cmd,
          focus = true,
          reopen = true,
          notify = true,
        })
      else
        refresh_mermaid_preview({
          source_buf = source_buf,
          mode = mermaid_preview_state.mode or "current",
          layout = "float",
          split_cmd = mermaid_preview_state.split_cmd,
          focus = true,
          reopen = true,
          notify = true,
        })
      end
    end

    vim.api.nvim_create_user_command("MarkdownMermaidAsciiCurrent", preview_current_mermaid_block, {})
    vim.api.nvim_create_user_command("MarkdownMermaidAsciiAll", preview_all_mermaid_blocks, {})
    vim.api.nvim_create_user_command("MarkdownMermaidAsciiSelection", preview_visual_mermaid_selection, { range = true })
    vim.api.nvim_create_user_command("MarkdownMermaidAsciiCurrentVertical", function()
      preview_current_mermaid_block({ layout = "vertical", split_cmd = "botright vsplit" })
    end, {})
    vim.api.nvim_create_user_command("MarkdownMermaidAsciiAllVertical", function()
      preview_all_mermaid_blocks({ layout = "vertical", split_cmd = "botright vsplit" })
    end, {})
    vim.api.nvim_create_user_command("MarkdownMermaidAsciiFloatToggle", toggle_mermaid_preview_float, {})
    vim.api.nvim_create_user_command("MarkdownBrowserPreviewToggle", toggle_markdown_browser_preview, {})
    vim.api.nvim_create_user_command("MarkdownMermaidAsciiSelectionVertical", function()
      preview_visual_mermaid_selection({ layout = "vertical", split_cmd = "botright vsplit" })
    end, {})

    --- More commands can be configured (https://github.com/MeanderingProgrammer/render-markdown.nvim?tab=readme-ov-file#commands)
    keymapd("<leader>lem", "LSP: Toggle Markdown rendering", markdownPlugin.toggle)
    keymapd("<leader>lmh", "Markdown: Preview Mermaid block horizontally", preview_current_mermaid_block)
    keymapd("<leader>lmH", "Markdown: Preview all Mermaid blocks horizontally", preview_all_mermaid_blocks)
    keymapd("<leader>lmm", "Markdown: Preview Mermaid block vertically", function()
      preview_current_mermaid_block({ layout = "vertical", split_cmd = "botright vsplit" })
    end)
    keymapd("<leader>lmM", "Markdown: Preview all Mermaid blocks vertically", function()
      preview_all_mermaid_blocks({ layout = "vertical", split_cmd = "botright vsplit" })
    end)
    keymapd("<leader>lmf", "Markdown: Toggle Mermaid preview floating mode", toggle_mermaid_preview_float)
    keymapd("<leader>lmv", "Markdown: Toggle browser preview", toggle_markdown_browser_preview)
    xkeymapd("<leader>lmh", "Markdown: Preview selected Mermaid horizontally", function()
      preview_visual_mermaid_selection({ layout = "horizontal", split_cmd = "botright split" })
    end)
    xkeymapd("<leader>lmm", "Markdown: Preview selected Mermaid vertically", function()
      preview_visual_mermaid_selection({ layout = "vertical", split_cmd = "botright vsplit" })
    end)
    xkeymapd("<leader>lmf", "Markdown: Preview selected Mermaid in floating mode", function()
      preview_visual_mermaid_selection({ layout = "float", split_cmd = mermaid_preview_state.split_cmd })
    end)
  '';
in {
  inherit name lua;

  vimPackages = with pkgs.vimPlugins; [
    markdown-preview-nvim
    render-markdown-nvim
    mini-nvim
    nvim-treesitter
  ];

  packages = with pkgs; [
    markdownlint-cli
    mermaidAscii
  ];
}
