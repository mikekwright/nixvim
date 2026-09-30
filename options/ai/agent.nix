{ ... }:

let
  name = "ai.agent";

  # Two fixed AI agents: opencode (default) and claude-code.
  # The binaries live in ai.binaries (full mode only) or come from system installs.
  lua = /*lua*/ ''
    -- AI Agent Configuration Module
    -- Hosts two AI agent terminals (OpenCode and Claude Code), each in its own
    -- uniquely named buffer, plus a shared prompt buffer for larger contexts.

    local AI_AGENTS = {
      opencode = {
        id = "opencode",
        name = "OpenCode",
        command = "opencode",
        marker = "is_opencode_terminal",
        buffer_name = "AI:opencode",
        init_wait_ms = 10000,
      },
      claude = {
        id = "claude",
        name = "Claude Code",
        command = "claude",
        marker = "is_claude_terminal",
        buffer_name = "AI:claude-code",
        init_wait_ms = 5000,
      },
    }

    local function get_agent(agent_id)
      return AI_AGENTS[agent_id]
    end

    -- Resolve the command for an agent: bundled binaries (ai.binaries, full
    -- mode only) publish absolute paths via vim.g.ai_agent_commands; without
    -- them we fall back to the plain command found on PATH
    local function get_agent_command(agent)
      local bundled = vim.g.ai_agent_commands or {}
      return bundled[agent.id] or agent.command
    end

    -- Helper function to find an agent's terminal buffer
    local function find_agent_buffer(agent)
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
          local ok, is_agent = pcall(vim.api.nvim_buf_get_var, buf, agent.marker)
          if ok and is_agent then
            return buf
          end
        end
      end
      return nil
    end

    -- Helper function to create an agent terminal in the current window
    local function create_agent_terminal(agent)
      local buf = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_set_current_buf(buf)
      vim.fn.termopen(get_agent_command(agent))
      pcall(vim.api.nvim_buf_set_name, buf, agent.buffer_name)
      vim.api.nvim_buf_set_var(buf, agent.marker, true)
      return buf
    end

    -- Function to open or switch to an agent terminal
    function open_agent_terminal(agent_id)
      local agent = get_agent(agent_id)
      local agent_buf = find_agent_buffer(agent)
      local agent_win = agent_buf and find_window_for_buffer(agent_buf) or nil

      local current_buf = vim.api.nvim_get_current_buf()
      local is_alpha = vim.bo[current_buf].filetype == "alpha"

      if agent_buf and agent_win then
        if is_alpha then
          vim.api.nvim_buf_delete(current_buf, { force = true })
        end
        vim.api.nvim_set_current_win(agent_win)
      elseif agent_buf then
        vim.api.nvim_set_current_buf(agent_buf)
        vim.cmd('startinsert')
      else
        create_agent_terminal(agent)
        vim.cmd('startinsert')
      end
    end

    -- Helper function to ensure an agent terminal exists and is ready
    local function with_agent_terminal(agent_id, callback, on_error)
      local agent = get_agent(agent_id)
      local agent_buf = find_agent_buffer(agent)
      local terminal_already_existed = agent_buf ~= nil

      if agent_buf then
        local ok, job_id = pcall(vim.api.nvim_buf_get_var, agent_buf, "terminal_job_id")
        if ok and job_id then
          callback(job_id, agent_buf)
          return
        end
      end

      if not agent_buf then
        print(agent.name .. " terminal not found, creating one...")
        open_agent_terminal(agent_id)
      end

      vim.defer_fn(function()
        local retry_count = 0
        local max_retries = 10

        local function try_callback()
          retry_count = retry_count + 1
          local cb = find_agent_buffer(agent)

          if cb then
            local ok, job_id = pcall(vim.api.nvim_buf_get_var, cb, "terminal_job_id")
            if ok and job_id then
              if not terminal_already_existed then
                print("Waiting for " .. agent.name .. " to initialize...")
                vim.defer_fn(function()
                  callback(job_id, cb)
                end, agent.init_wait_ms)
              else
                callback(job_id, cb)
              end
              return
            end
          end

          if retry_count < max_retries then
            vim.defer_fn(try_callback, 100)
          else
            local error_msg = "Terminal initialization timeout"
            if on_error then
              on_error(error_msg)
            else
              print("Failed: " .. error_msg)
            end
          end
        end

        try_callback()
      end, 100)
    end

    -- Function to restart an agent in its terminal
    local function restart_agent_terminal(agent_id)
      local agent = get_agent(agent_id)
      local agent_buf = find_agent_buffer(agent)
      if not agent_buf then
        print(agent.name .. " terminal not found, creating new one...")
        open_agent_terminal(agent_id)
        return
      end

      local job_id = vim.api.nvim_buf_get_var(agent_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "\x03")
        vim.defer_fn(function()
          vim.fn.chansend(job_id, get_agent_command(agent) .. "\n")
        end, 100)
      end

      local agent_win = find_window_for_buffer(agent_buf)
      if agent_win then
        vim.api.nvim_set_current_win(agent_win)
      else
        vim.cmd('split')
        vim.api.nvim_set_current_buf(agent_buf)
      end

      vim.cmd('startinsert')
      print(agent.name .. " terminal restarted")
    end

    -- Function to open an agent terminal in vertical split
    local function open_agent_terminal_vertical(agent_id)
      local agent = get_agent(agent_id)
      local agent_buf = find_agent_buffer(agent)
      local agent_win = agent_buf and find_window_for_buffer(agent_buf) or nil

      if agent_buf and agent_win then
        vim.api.nvim_set_current_win(agent_win)
      elseif agent_buf then
        vim.cmd('vsplit')
        vim.api.nvim_set_current_buf(agent_buf)
      else
        vim.cmd('vsplit')
        create_agent_terminal(agent)
        vim.cmd('startinsert')
      end
    end

    -- Function to hide an agent terminal if visible
    local function hide_agent_terminal(agent_id)
      local agent = get_agent(agent_id)
      local agent_buf = find_agent_buffer(agent)
      if not agent_buf then
        return
      end

      local agent_win = find_window_for_buffer(agent_buf)
      if agent_win then
        vim.api.nvim_win_close(agent_win, false)
      end
    end

    -- Function to exit an agent
    local function exit_agent(agent_id)
      local agent = get_agent(agent_id)
      local agent_buf = find_agent_buffer(agent)
      if not agent_buf then
        print(agent.name .. " terminal not found")
        return
      end

      local job_id = vim.api.nvim_buf_get_var(agent_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "/exit\n")
      end
    end

    -- Function to interrupt current agent command
    local function interrupt_agent(agent_id)
      local agent = get_agent(agent_id)
      local agent_buf = find_agent_buffer(agent)
      if not agent_buf then
        print(agent.name .. " terminal not found")
        return
      end

      local job_id = vim.api.nvim_buf_get_var(agent_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "\x03")
        print("Sent interrupt signal to " .. agent.name)
      end
    end

    -- Function to send newline to an agent
    local function send_newline_to_agent(agent_id)
      local agent = get_agent(agent_id)
      local agent_buf = find_agent_buffer(agent)
      if not agent_buf then
        print(agent.name .. " terminal not found")
        return
      end

      local job_id = vim.api.nvim_buf_get_var(agent_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "\n")
      end
    end

    -- Forward declaration for open_agent_prompt
    local open_agent_prompt

    -- Helper function to setup keymaps for prompt buffer
    local function setup_prompt_keymaps(buf, win)
      local function close_prompt()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, false)
        end
      end

      local function submit_to_agent(agent_id)
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local text = table.concat(lines, "\n")

        -- Check if prompt is in floating mode
        local ok, is_floating = pcall(vim.api.nvim_buf_get_var, buf, "prompt_is_floating")
        if not ok then
          is_floating = true
        end

        if is_floating then
          -- Floating mode: close window and delete buffer
          close_prompt()
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
        else
          -- Non-floating mode: clear buffer content but keep window open
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
          end
        end

        with_agent_terminal(agent_id, function(job_id, agent_buf)
          vim.fn.chansend(job_id, text)
          vim.fn.chansend(job_id, "\n")

          local agent_win = find_window_for_buffer(agent_buf)
          if agent_win then
            vim.api.nvim_set_current_win(agent_win)
          else
            vim.cmd('split')
            vim.api.nvim_set_current_buf(agent_buf)
          end

          vim.cmd('stopinsert')
        end, function(error_msg)
          print("Failed to send text: " .. error_msg)
        end)
      end

      local function buf_keymap(mode, key, callback)
        pcall(vim.api.nvim_buf_del_keymap, buf, mode, key)
        vim.api.nvim_buf_set_keymap(buf, mode, key, "", {
          callback = callback,
          noremap = true,
          silent = true,
        })
      end

      buf_keymap("i", "<C-x>", close_prompt)
      buf_keymap("n", "<leader>ax", close_prompt)

      buf_keymap("i", "<C-s>a", function() submit_to_agent("opencode") end)
      buf_keymap("i", "<C-s>c", function() submit_to_agent("claude") end)
      buf_keymap("n", "<leader>asa", function() submit_to_agent("opencode") end)
      buf_keymap("n", "<leader>asc", function() submit_to_agent("claude") end)
    end

    -- Helper function to find agent prompt buffer (even if hidden)
    local function find_agent_prompt_buffer()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
          local ok, is_prompt = pcall(vim.api.nvim_buf_get_var, buf, "is_agent_prompt")
          if ok and is_prompt then
            return buf
          end
        end
      end
      return nil
    end

    -- Helper function to find agent prompt window
    local function find_agent_prompt()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) then
          local buf = vim.api.nvim_win_get_buf(win)
          local ok, is_prompt = pcall(vim.api.nvim_buf_get_var, buf, "is_agent_prompt")
          if ok and is_prompt then
            return win, buf
          end
        end
      end
      return nil, nil
    end

    -- Helper function to insert text into prompt window at cursor
    local function insert_text_into_prompt(text)
      local prompt_win, prompt_buf = find_agent_prompt()

      -- Split text into lines for proper insertion
      local lines = vim.split(text, "\n", { plain = true })

      -- If prompt window doesn't exist, create it with text
      if not prompt_win then
        open_agent_prompt(text)
      else
        -- Focus the existing prompt window and insert text
        vim.api.nvim_set_current_win(prompt_win)
        -- Insert text at cursor (nvim_put expects array of lines)
        vim.api.nvim_put(lines, "c", true, true)
      end
    end

    -- Function to send selected text to the agent prompt buffer
    local function send_selection_to_agent()
      -- Get visual selection marks
      local bufnr = vim.api.nvim_get_current_buf()
      local start_pos = vim.fn.getpos("'<")
      local end_pos = vim.fn.getpos("'>")
      local start_line = start_pos[2]
      local start_col = start_pos[3]
      local end_line = end_pos[2]
      local end_col = end_pos[3]

      -- Validate that marks are set
      if start_line == 0 or end_line == 0 then
        print("No valid visual selection marks")
        return
      end

      -- Get all lines in the selection range (0-indexed for nvim_buf_get_lines)
      local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)

      if #lines == 0 then
        print("No text selected")
        return
      end

      -- Handle single line selection
      if #lines == 1 then
        lines[1] = string.sub(lines[1], start_col, end_col)
      else
        -- Handle multi-line selection
        lines[1] = string.sub(lines[1], start_col)
        lines[#lines] = string.sub(lines[#lines], 1, end_col)
      end

      -- Filter out empty result
      if #lines == 1 and lines[1] == "" then
        print("No text selected")
        return
      end

      -- Join lines with newlines for multi-line selections
      local text = table.concat(lines, "\n")

      -- Wrap in code block with triple backticks
      text = "```\n" .. text .. "\n```"

      -- Insert into prompt window
      insert_text_into_prompt(text)
    end

    -- Function to send current file path to the agent prompt buffer
    local function send_filepath_to_agent()
      -- - %:p - Full absolute path (current behavior)
      -- - %:. - Path relative to current working directory
      -- - %:~ - Path relative to home directory
      -- - %:t - Filename only (tail)
      -- - %:h - Directory name only (head)
      local filepath = vim.fn.expand("%:.")
      if filepath == "" then
        print("No file in current buffer")
        return
      end

      -- Insert filepath into prompt window
      insert_text_into_prompt(filepath)
    end

    -- Function to open floating prompt window for agents
    open_agent_prompt = function(initial_text)
      -- Check if prompt window is already visible
      local existing_win, existing_buf = find_agent_prompt()
      if existing_win then
        -- Window is already open, just focus it
        vim.api.nvim_set_current_win(existing_win)

        -- If initial text provided, insert it
        if initial_text and initial_text ~= "" then
          local lines = vim.split(initial_text, "\n", { plain = true })
          vim.api.nvim_put(lines, "c", true, true)
        end

        -- Only start in insert mode if no initial text was provided
        if not initial_text or initial_text == "" then
          vim.cmd('startinsert')
        end
        return
      end

      -- Check if a hidden prompt buffer exists
      local buf = find_agent_prompt_buffer()
      local is_new_buffer = false

      if not buf then
        -- Create new buffer if none exists
        buf = vim.api.nvim_create_buf(false, true)
        is_new_buffer = true
      end

      -- Check if prompt should be floating (default: true)
      local is_floating = true
      if not is_new_buffer then
        local ok, floating = pcall(vim.api.nvim_buf_get_var, buf, "prompt_is_floating")
        if ok then
          is_floating = floating
        end
      end

      local win

      if is_floating then
        -- Create floating window
        local width = vim.api.nvim_get_option("columns")
        local height = vim.api.nvim_get_option("lines")

        local win_width = math.floor(width * 0.8)
        local win_height = math.floor(height * 0.8)

        local row = math.floor((height - win_height) / 2)
        local col = math.floor((width - win_width) / 2)

        local opts = {
          relative = "editor",
          width = win_width,
          height = win_height,
          row = row,
          col = col,
          style = "minimal",
          border = "rounded",
          title = " AI Agent Prompt ",
          title_pos = "center",
        }

        win = vim.api.nvim_open_win(buf, true, opts)
      else
        -- Create split window
        vim.cmd('vsplit')
        win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(win, buf)
      end

      -- Only set buffer options for new buffers
      if is_new_buffer then
        vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
        vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
        vim.api.nvim_buf_set_var(buf, "is_agent_prompt", true)
        vim.api.nvim_buf_set_var(buf, "prompt_is_floating", true)
      end

      vim.api.nvim_win_set_option(win, "wrap", true)
      vim.api.nvim_win_set_option(win, "linebreak", true)

      -- If initial text provided, insert it
      if initial_text and initial_text ~= "" then
        -- Split text into lines for proper insertion
        local lines = vim.split(initial_text, "\n", { plain = true })
        vim.api.nvim_put(lines, "c", true, true)
      end

      -- Setup keymaps for the prompt buffer
      setup_prompt_keymaps(buf, win)

      -- Only start in insert mode if no initial text was provided
      if not initial_text or initial_text == "" then
        vim.cmd('startinsert')
      end
    end

    -- Function to hide agent prompt window if visible
    local function hide_agent_prompt()
      local prompt_win, prompt_buf = find_agent_prompt()
      if not prompt_win then
        return
      end

      if vim.api.nvim_win_is_valid(prompt_win) then
        vim.api.nvim_win_close(prompt_win, false)
      end
    end

    -- Function to toggle floating mode for agent prompt
    local function toggle_agent_prompt_float()
      local prompt_win, prompt_buf = find_agent_prompt()

      -- If no window is visible, try to find the buffer
      if not prompt_buf then
        prompt_buf = find_agent_prompt_buffer()
      end

      if not prompt_buf then
        print("No agent prompt buffer exists")
        return
      end

      -- Get current floating state
      local ok, is_floating = pcall(vim.api.nvim_buf_get_var, prompt_buf, "prompt_is_floating")
      if not ok then
        is_floating = true
      end

      -- Toggle the state
      local new_floating = not is_floating
      vim.api.nvim_buf_set_var(prompt_buf, "prompt_is_floating", new_floating)

      -- If window is currently open, close and reopen in new mode
      if prompt_win then
        -- Save cursor position
        local cursor_pos = vim.api.nvim_win_get_cursor(prompt_win)

        -- Close the window
        vim.api.nvim_win_close(prompt_win, false)

        -- Reopen in new mode
        open_agent_prompt()

        -- Restore cursor position
        local new_win = find_agent_prompt()
        if new_win then
          pcall(vim.api.nvim_win_set_cursor, new_win, cursor_pos)
        end

        print("Prompt mode: " .. (new_floating and "floating" or "split"))
      else
        print("Prompt will open in " .. (new_floating and "floating" or "split") .. " mode next time")
      end
    end

    -- Function to setup agent mode layout for a specific agent
    local function setup_agent_mode(agent_id)
      local agent = get_agent(agent_id)

      -- Save the current window
      local original_win = vim.api.nvim_get_current_win()

      -- Get total width
      local total_width = vim.api.nvim_get_option("columns")
      local right_width = math.floor(total_width * 0.25)

      -- Create vertical split on the right
      vim.cmd('rightbelow vsplit')
      local right_win = vim.api.nvim_get_current_win()

      -- Set the width of the right window
      vim.api.nvim_win_set_width(right_win, right_width)

      -- Get the height for splitting
      local win_height = vim.api.nvim_win_get_height(right_win)
      local terminal_height = math.floor(win_height * 0.75)

      -- Open agent terminal in the right window
      local agent_buf = find_agent_buffer(agent)

      if not agent_buf then
        create_agent_terminal(agent)
      else
        -- Use existing agent terminal
        vim.api.nvim_win_set_buf(right_win, agent_buf)
      end

      -- Create horizontal split for prompt (below terminal)
      vim.cmd('belowright split')
      local prompt_win = vim.api.nvim_get_current_win()

      -- Set terminal window height (go back to terminal window to set its height)
      vim.api.nvim_set_current_win(right_win)
      vim.api.nvim_win_set_height(right_win, terminal_height)
      vim.api.nvim_set_current_win(prompt_win)

      -- Setup prompt buffer in bottom split
      local prompt_buf = find_agent_prompt_buffer()

      if not prompt_buf then
        -- Create new prompt buffer
        prompt_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(prompt_buf, "bufhidden", "hide")
        vim.api.nvim_buf_set_option(prompt_buf, "filetype", "markdown")
        vim.api.nvim_buf_set_var(prompt_buf, "is_agent_prompt", true)
        vim.api.nvim_buf_set_var(prompt_buf, "prompt_is_floating", false)
      else
        -- Update existing buffer to non-floating mode
        vim.api.nvim_buf_set_var(prompt_buf, "prompt_is_floating", false)
      end

      vim.api.nvim_win_set_buf(prompt_win, prompt_buf)
      vim.api.nvim_win_set_option(prompt_win, "wrap", true)
      vim.api.nvim_win_set_option(prompt_win, "linebreak", true)

      -- Setup keymaps for the prompt buffer
      setup_prompt_keymaps(prompt_buf, prompt_win)

      -- Return focus to original window
      vim.api.nvim_set_current_win(original_win)

      print(agent.name .. " mode layout activated")
    end

    -- Register agent prompt completion disable check
    register_completion_disable_check(function()
      local ok, is_agent_prompt = pcall(vim.api.nvim_buf_get_var, 0, "is_agent_prompt")
      return ok and is_agent_prompt
    end, "AI Agent prompt window")

    -- Function to clear the agent prompt buffer
    local function clear_agent_prompt()
      local prompt_buf = find_agent_prompt_buffer()
      if prompt_buf and vim.api.nvim_buf_is_valid(prompt_buf) then
        vim.api.nvim_buf_set_lines(prompt_buf, 0, -1, false, {})
        print("Agent prompt buffer cleared")
      else
        print("No agent prompt buffer found")
      end
    end

    -- Wrapper function to escape terminal mode and open an agent terminal
    local function escape_terminal_and_open_agent(agent_id)
      vim.cmd("stopinsert")
      vim.schedule(function()
        open_agent_terminal(agent_id)
      end)
    end

    -- Register dashboard actions
    register_dashboard_action("a", "OpenCode", ":lua open_agent_terminal('opencode')<CR>")
    register_dashboard_action("c", "Claude Code", ":lua open_agent_terminal('claude')<CR>")

    -- Keyboard shortcuts: terminals
    keymapd("<leader>aa", "Open/Switch to OpenCode terminal", function() open_agent_terminal("opencode") end)
    keymapd("<leader>ac", "Open/Switch to Claude Code terminal", function() open_agent_terminal("claude") end)
    keymapd("<leader>ava", "Open OpenCode terminal (vertical split)", function() open_agent_terminal_vertical("opencode") end)
    keymapd("<leader>avc", "Open Claude Code terminal (vertical split)", function() open_agent_terminal_vertical("claude") end)
    keymapd("<leader>aha", "Hide OpenCode terminal", function() hide_agent_terminal("opencode") end)
    keymapd("<leader>ahc", "Hide Claude Code terminal", function() hide_agent_terminal("claude") end)
    keymapd("<leader>ara", "Restart OpenCode in terminal", function() restart_agent_terminal("opencode") end)
    keymapd("<leader>arc", "Restart Claude Code in terminal", function() restart_agent_terminal("claude") end)
    keymapd("<leader>aea", "Exit OpenCode terminal", function() exit_agent("opencode") end)
    keymapd("<leader>aec", "Exit Claude Code terminal", function() exit_agent("claude") end)
    keymapd("<leader>aia", "Interrupt OpenCode command (Ctrl-C)", function() interrupt_agent("opencode") end)
    keymapd("<leader>aic", "Interrupt Claude Code command (Ctrl-C)", function() interrupt_agent("claude") end)
    keymapd("<leader>ana", "Send newline to OpenCode", function() send_newline_to_agent("opencode") end)
    keymapd("<leader>anc", "Send newline to Claude Code", function() send_newline_to_agent("claude") end)
    keymapd("<leader>ama", "Setup OpenCode mode layout", function() setup_agent_mode("opencode") end)
    keymapd("<leader>amc", "Setup Claude Code mode layout", function() setup_agent_mode("claude") end)

    -- Keyboard shortcuts: shared prompt buffer
    keymapd("<leader>app", "Open AI agent prompt window", open_agent_prompt)
    keymapd("<leader>aph", "Hide AI agent prompt window", hide_agent_prompt)
    keymapd("<leader>apf", "Toggle AI agent prompt floating mode", toggle_agent_prompt_float)
    keymapd("<leader>apc", "Clear AI agent prompt buffer", clear_agent_prompt)
    ikeymapd("<C-p>", "Open AI agent prompt window", open_agent_prompt)
    tkeymapd("<C-p>", "Open AI agent prompt window", open_agent_prompt)
    keymapd("<leader>af", "Send current file path to AI agent prompt", send_filepath_to_agent)
    vim.keymap.set("x", "<leader>as", function()
      -- Store a reference to the function to be called after exiting visual mode
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
      vim.schedule(function()
        send_selection_to_agent()
      end)
    end, { silent = true, noremap = true, desc = "Send selection to AI agent prompt" })

    -- Keyboard shortcuts: navigation
    keymapd("<C-w>aa", "Navigate to OpenCode", function() open_agent_terminal("opencode") end)
    keymapd("<C-w>ac", "Navigate to Claude Code", function() open_agent_terminal("claude") end)
    tkeymapd("<C-w>aa", "Navigate to OpenCode from terminal", function() escape_terminal_and_open_agent("opencode") end)
    tkeymapd("<C-w>ac", "Navigate to Claude Code from terminal", function() escape_terminal_and_open_agent("claude") end)
  '';
in
{
  inherit name lua;
}
