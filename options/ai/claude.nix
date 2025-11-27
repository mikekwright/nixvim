{ pkgs, ... }:

let
  name = "ai.claude";

  lua = /*lua*/ ''
    -- Register Claude button with the greeter
    register_dashboard_action("c", "Claude AI", ":lua open_claude_terminal()<CR>")

    -- Helper function to find Claude terminal buffer
    local function find_claude_buffer()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
          -- Check if buffer has our special marker variable
          local ok, is_claude = pcall(vim.api.nvim_buf_get_var, buf, "is_claude_terminal")
          if ok and is_claude then
            return buf
          end
        end
      end
      return nil
    end

    -- Function to open or switch to Claude terminal
    function open_claude_terminal()
      local claude_buf = find_claude_buffer()
      local claude_win = claude_buf and find_window_for_buffer(claude_buf) or nil

      -- Check if current buffer is alpha dashboard
      local current_buf = vim.api.nvim_get_current_buf()
      local is_alpha = vim.bo[current_buf].filetype == "alpha"

      if claude_buf and claude_win then
        -- Buffer exists and is visible
        if is_alpha then
          -- Close dashboard and switch to Claude window
          vim.api.nvim_buf_delete(current_buf, { force = true })
          vim.api.nvim_set_current_win(claude_win)
        else
          -- Just switch to Claude window
          vim.api.nvim_set_current_win(claude_win)
        end
      elseif claude_buf then
        -- Buffer exists but not visible
        if is_alpha then
          -- Replace dashboard with Claude buffer
          vim.api.nvim_set_current_buf(claude_buf)
        else
          -- Open in a new split
          vim.cmd('split')
          vim.api.nvim_set_current_buf(claude_buf)
        end
      else
        -- Buffer doesn't exist, create new terminal
        if is_alpha then
          -- Replace dashboard with new Claude terminal
          local buf = vim.api.nvim_create_buf(true, false)
          vim.api.nvim_set_current_buf(buf)
          vim.fn.termopen("claude")
          -- Mark this buffer as the Claude terminal
          vim.api.nvim_buf_set_var(buf, "is_claude_terminal", true)
          vim.cmd('startinsert')
        else
          -- Open in a split
          vim.cmd('split')
          local buf = vim.api.nvim_create_buf(true, false)
          vim.api.nvim_set_current_buf(buf)
          vim.fn.termopen("claude")
          -- Mark this buffer as the Claude terminal
          vim.api.nvim_buf_set_var(buf, "is_claude_terminal", true)
          vim.cmd('startinsert')
        end
      end
    end

    -- Helper function to ensure Claude terminal exists and is ready, then execute callback
    -- If terminal doesn't exist, it will be created and callback will be executed once ready
    -- callback receives (job_id, claude_buf) as parameters
    local function with_claude_terminal(callback, on_error)
      local claude_buf = find_claude_buffer()
      local terminal_already_existed = claude_buf ~= nil

      if claude_buf then
        -- Terminal exists, try to get job_id
        local ok, job_id = pcall(vim.api.nvim_buf_get_var, claude_buf, "terminal_job_id")
        if ok and job_id then
          callback(job_id, claude_buf)
          return
        end
      end

      -- Terminal doesn't exist or isn't ready, create it
      if not claude_buf then
        print("Claude terminal not found, creating one...")
        open_claude_terminal()
      end

      -- Wait for terminal to initialize with retry logic
      vim.defer_fn(function()
        local retry_count = 0
        local max_retries = 10

        local function try_callback()
          retry_count = retry_count + 1
          local cb = find_claude_buffer()

          if cb then
            local ok, job_id = pcall(vim.api.nvim_buf_get_var, cb, "terminal_job_id")
            if ok and job_id then
              -- Terminal is ready, but if we just created it, wait for Claude to fully initialize
              if not terminal_already_existed then
                print("Waiting for Claude to initialize...")
                vim.defer_fn(function()
                  callback(job_id, cb)
                end, 5000)  -- 5 second delay for Claude to fully start
              else
                callback(job_id, cb)
              end
              return
            end
          end

          -- If terminal not ready and we haven't exceeded retries, try again
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

    -- Function to close Claude terminal
    local function close_claude_terminal()
      local claude_buf = find_claude_buffer()
      if not claude_buf then
        print("Claude terminal not found")
        return
      end

      local claude_win = find_window_for_buffer(claude_buf)
      if claude_win then
        -- Close the window
        vim.api.nvim_win_close(claude_win, false)
      end

      -- Delete the buffer (this will kill the terminal process)
      vim.api.nvim_buf_delete(claude_buf, { force = true })
      print("Claude terminal closed")
    end

    -- Function to restart Claude in the terminal
    local function restart_claude_terminal()
      local claude_buf = find_claude_buffer()
      if not claude_buf then
        print("Claude terminal not found, creating new one...")
        open_claude_terminal()
        return
      end

      -- Get the job ID for the terminal
      local job_id = vim.api.nvim_buf_get_var(claude_buf, "terminal_job_id")
      if job_id then
        -- Send Ctrl-C to terminate current process
        vim.fn.chansend(job_id, "\x03")
        -- Wait a brief moment
        vim.defer_fn(function()
          -- Start claude again
          vim.fn.chansend(job_id, "claude\n")
        end, 100)
      end

      -- Switch to the terminal window if not already there
      local claude_win = find_window_for_buffer(claude_buf)
      if claude_win then
        vim.api.nvim_set_current_win(claude_win)
      else
        vim.cmd('split')
        vim.api.nvim_set_current_buf(claude_buf)
      end

      vim.cmd('startinsert')
      print("Claude terminal restarted")
    end

    -- Function to toggle Claude terminal visibility
    local function toggle_claude_terminal()
      local claude_buf = find_claude_buffer()
      if not claude_buf then
        open_claude_terminal()
        return
      end

      local claude_win = find_window_for_buffer(claude_buf)
      if claude_win then
        -- Window is visible, hide it
        vim.api.nvim_win_close(claude_win, false)
      else
        -- Window is hidden, show it
        vim.cmd('split')
        vim.api.nvim_set_current_buf(claude_buf)
      end
    end

    -- Function to open Claude terminal in vertical split
    local function open_claude_terminal_vertical()
      local claude_buf = find_claude_buffer()
      local claude_win = claude_buf and find_window_for_buffer(claude_buf) or nil

      if claude_buf and claude_win then
        -- Buffer exists and is visible, switch to it
        vim.api.nvim_set_current_win(claude_win)
      elseif claude_buf then
        -- Buffer exists but not visible, open it in a new vertical split
        vim.cmd('vsplit')
        vim.api.nvim_set_current_buf(claude_buf)
      else
        -- Buffer doesn't exist, create new terminal in vertical split
        vim.cmd('vsplit')
        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buf)
        vim.fn.termopen("claude")
        -- Mark this buffer as the Claude terminal
        vim.api.nvim_buf_set_var(buf, "is_claude_terminal", true)
        vim.cmd('startinsert')
      end
    end

    -- Function to clear Claude terminal screen
    local function clear_claude_terminal()
      local claude_buf = find_claude_buffer()
      if not claude_buf then
        print("Claude terminal not found")
        return
      end

      local job_id = vim.api.nvim_buf_get_var(claude_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "clear\n")
      end
    end

    -- Function to send help command to Claude
    local function send_claude_help()
      local claude_buf = find_claude_buffer()
      if not claude_buf then
        print("Claude terminal not found")
        return
      end

      local job_id = vim.api.nvim_buf_get_var(claude_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "/help\n")
      end

      -- Switch to the terminal
      local claude_win = find_window_for_buffer(claude_buf)
      if claude_win then
        vim.api.nvim_set_current_win(claude_win)
      end
    end

    -- Function to exit Claude
    local function exit_claude()
      local claude_buf = find_claude_buffer()
      if not claude_buf then
        print("Claude terminal not found")
        return
      end

      local job_id = vim.api.nvim_buf_get_var(claude_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "/exit\n")
      end
    end

    -- Function to send selected text to Claude terminal
    local function send_selection_to_claude()
      -- Get the selected text first
      local start_pos = vim.fn.getpos("'<")
      local end_pos = vim.fn.getpos("'>")
      local lines = vim.fn.getline(start_pos[2], end_pos[2])

      if #lines == 0 then
        print("No text selected")
        return
      end

      -- Handle single line selection
      if #lines == 1 then
        lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
      else
        -- Handle multi-line selection
        lines[1] = string.sub(lines[1], start_pos[3])
        lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
      end

      with_claude_terminal(function(job_id, claude_buf)
        for _, line in ipairs(lines) do
          vim.fn.chansend(job_id, line .. "\n")
        end
        print("Selection sent to Claude terminal")
      end, function(error_msg)
        print("Failed to send selection: " .. error_msg)
      end)
    end

    -- Function to send current file path to Claude
    local function send_filepath_to_claude()
      local filepath = vim.fn.expand("%:p")
      if filepath == "" then
        print("No file in current buffer")
        return
      end

      with_claude_terminal(function(job_id, claude_buf)
        vim.fn.chansend(job_id, filepath)
        print("File path sent to Claude terminal: " .. filepath)
      end, function(error_msg)
        print("Failed to send filepath: " .. error_msg)
      end)
    end

    -- Function to interrupt current Claude command
    local function interrupt_claude()
      local claude_buf = find_claude_buffer()
      if not claude_buf then
        print("Claude terminal not found")
        return
      end

      local job_id = vim.api.nvim_buf_get_var(claude_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "\x03")
        print("Sent interrupt signal to Claude")
      end
    end

    -- Function to maximize Claude terminal window
    local function maximize_claude_terminal()
      local claude_buf = find_claude_buffer()
      if not claude_buf then
        print("Claude terminal not found, creating new one...")
        open_claude_terminal()
        return
      end

      local claude_win = find_window_for_buffer(claude_buf)
      if not claude_win then
        -- If window doesn't exist, create it as maximized
        vim.cmd('tabnew')
        vim.api.nvim_set_current_buf(claude_buf)
      else
        -- Switch to window and maximize it
        vim.api.nvim_set_current_win(claude_win)
        vim.cmd('only')
      end
    end

    -- Function to send newline to Claude
    local function send_newline_to_claude()
      local claude_buf = find_claude_buffer()
      if not claude_buf then
        print("Claude terminal not found")
        return
      end

      local job_id = vim.api.nvim_buf_get_var(claude_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "\n")
      end
    end

    -- Function to open claude.ai in default web browser
    local function open_claude_web()
      vim.fn.system("xdg-open https://claude.ai")
      print("Opening claude.ai in default browser")
    end

    -- Function to open floating prompt window for Claude
    local function open_claude_prompt()
      -- Create a buffer for the floating window
      local buf = vim.api.nvim_create_buf(false, true)  -- Not listed, scratch buffer

      -- Get editor dimensions
      local width = vim.api.nvim_get_option("columns")
      local height = vim.api.nvim_get_option("lines")

      -- Calculate floating window size (80% of editor)
      local win_width = math.floor(width * 0.8)
      local win_height = math.floor(height * 0.8)

      -- Calculate starting position (centered)
      local row = math.floor((height - win_height) / 2)
      local col = math.floor((width - win_width) / 2)

      -- Window options
      local opts = {
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = " Claude Prompt ",
        title_pos = "center",
      }

      -- Open the floating window
      local win = vim.api.nvim_open_win(buf, true, opts)

      -- Set buffer options
      vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
      vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

      -- Function to close the floating window
      local function close_prompt()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end

      -- Function to submit text to Claude
      local function submit_to_claude()
        -- Get all text from the buffer
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local text = table.concat(lines, "\n")

        -- Close the floating window
        close_prompt()

        with_claude_terminal(function(job_id, claude_buf)
          -- Send text to Claude
          vim.fn.chansend(job_id, text)
          vim.fn.chansend(job_id, "\n")

          -- Focus Claude terminal in normal mode
          local claude_win = find_window_for_buffer(claude_buf)
          if claude_win then
            vim.api.nvim_set_current_win(claude_win)
          else
            vim.cmd('split')
            vim.api.nvim_set_current_buf(claude_buf)
          end

          -- Ensure we're in normal mode
          vim.cmd('stopinsert')
        end, function(error_msg)
          print("Failed to send text: " .. error_msg)
        end)
      end

      -- Buffer-local keymaps for the floating window
      -- Insert mode: C-x to close
      vim.api.nvim_buf_set_keymap(buf, "i", "<C-x>", "", {
        callback = close_prompt,
        noremap = true,
        silent = true,
      })

      -- Insert mode: C-s to submit
      vim.api.nvim_buf_set_keymap(buf, "i", "<C-s>", "", {
        callback = submit_to_claude,
        noremap = true,
        silent = true,
      })

      -- Normal mode: <leader>ax to close
      vim.api.nvim_buf_set_keymap(buf, "n", "<leader>ax", "", {
        callback = close_prompt,
        noremap = true,
        silent = true,
      })

      -- Normal mode: <leader>as to submit
      vim.api.nvim_buf_set_keymap(buf, "n", "<leader>as", "", {
        callback = submit_to_claude,
        noremap = true,
        silent = true,
      })

      -- Start in insert mode
      vim.cmd('startinsert')
    end

    -- Keyboard shortcuts for Claude terminal
    keymapd("<leader>aa", "Open/Switch to Claude terminal", open_claude_terminal)
    keymapd("<leader>ap", "Open Claude prompt window", open_claude_prompt)
    ikeymapd("<C-p>", "Open Claude prompt window", open_claude_prompt)
    tkeymapd("<C-p>", "Open Claude prompt window", open_claude_prompt)
    keymapd("<leader>aq", "Close Claude terminal", close_claude_terminal)
    keymapd("<leader>ar", "Restart Claude in terminal", restart_claude_terminal)
    keymapd("<leader>at", "Toggle Claude terminal visibility", toggle_claude_terminal)
    keymapd("<leader>av", "Open Claude terminal (vertical split)", open_claude_terminal_vertical)
    keymapd("<leader>aw", "Open claude.ai in web browser", open_claude_web)
    keymapd("<leader>ac", "Clear Claude terminal screen", clear_claude_terminal)
    keymapd("<leader>ah", "Send /help to Claude", send_claude_help)
    keymapd("<leader>ae", "Exit Claude terminal", exit_claude)
    vkeymapd("<leader>as", "Send selection to Claude", send_selection_to_claude)
    keymapd("<leader>af", "Send current file path to Claude", send_filepath_to_claude)
    keymapd("<leader>ai", "Interrupt Claude command (Ctrl-C)", interrupt_claude)
    keymapd("<leader>al", "Maximize Claude terminal window", maximize_claude_terminal)
    keymapd("<leader>an", "Send newline to Claude", send_newline_to_claude)
  '';
in
{
  inherit name lua;

  packages = with pkgs; [
    claude-code
  ];
}
