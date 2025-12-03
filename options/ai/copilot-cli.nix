{ pkgs, ... }:

let
  name = "ai.copilot";

  # At this point (Nov 26, 2025) this is almost entirely an ai created module.
  #   there was a bit more back and forth, but its ability to land so close to where
  #   I was hoping it could land is pretty amazing.  Will manually tweak (or ai tweak
  #   where possible) over the next little while.
  lua = /*lua*/ ''
    -- Register Copilot button with the greeter
    register_dashboard_action("g", "Copilot AI", ":lua open_copilot_terminal()<CR>")

    -- Register completion disable check for Copilot prompt window
    register_completion_disable_check(function()
      local ok, is_copilot_prompt = pcall(vim.api.nvim_buf_get_var, 0, "is_copilot_prompt")
      return ok and is_copilot_prompt
    end, "Copilot prompt window")

    -- Helper function to find Copilot terminal buffer
    local function find_copilot_buffer()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
          -- Check if buffer has our special marker variable
          local ok, is_copilot = pcall(vim.api.nvim_buf_get_var, buf, "is_copilot_terminal")
          if ok and is_copilot then
            return buf
          end
        end
      end
      return nil
    end

    -- Function to open or switch to Copilot terminal
    function open_copilot_terminal()
      local copilot_buf = find_copilot_buffer()
      local copilot_win = copilot_buf and find_window_for_buffer(copilot_buf) or nil

      -- Check if current buffer is alpha dashboard
      local current_buf = vim.api.nvim_get_current_buf()
      local is_alpha = vim.bo[current_buf].filetype == "alpha"

      if copilot_buf and copilot_win then
        -- Buffer exists and is visible
        if is_alpha then
          -- Close dashboard and switch to Copilot window
          vim.api.nvim_buf_delete(current_buf, { force = true })
          vim.api.nvim_set_current_win(copilot_win)
        else
          -- Just switch to Copilot window
          vim.api.nvim_set_current_win(copilot_win)
        end
      elseif copilot_buf then
        -- Buffer exists but not visible
        if is_alpha then
          -- Replace dashboard with Copilot buffer
          vim.api.nvim_set_current_buf(copilot_buf)
        else
          -- Open in a new split
          vim.cmd('split')
          vim.api.nvim_set_current_buf(copilot_buf)
        end
      else
        -- Buffer doesn't exist, create new terminal
        if is_alpha then
          -- Replace dashboard with new Copilot terminal
          local buf = vim.api.nvim_create_buf(true, false)
          vim.api.nvim_set_current_buf(buf)
          vim.fn.termopen("copilot")
          -- Mark this buffer as the Copilot terminal
          vim.api.nvim_buf_set_var(buf, "is_copilot_terminal", true)
          vim.cmd('startinsert')
        else
          -- Open in a split
          vim.cmd('split')
          local buf = vim.api.nvim_create_buf(true, false)
          vim.api.nvim_set_current_buf(buf)
          vim.fn.termopen("copilot")
          -- Mark this buffer as the Copilot terminal
          vim.api.nvim_buf_set_var(buf, "is_copilot_terminal", true)
          vim.cmd('startinsert')
        end
      end
    end

    -- Helper function to ensure Copilot terminal exists and is ready, then execute callback
    -- If terminal doesn't exist, it will be created and callback will be executed once ready
    -- callback receives (job_id, copilot_buf) as parameters
    local function with_copilot_terminal(callback, on_error)
      local copilot_buf = find_copilot_buffer()
      local terminal_already_existed = copilot_buf ~= nil

      if copilot_buf then
        -- Terminal exists, try to get job_id
        local ok, job_id = pcall(vim.api.nvim_buf_get_var, copilot_buf, "terminal_job_id")
        if ok and job_id then
          callback(job_id, copilot_buf)
          return
        end
      end

      -- Terminal doesn't exist or isn't ready, create it
      if not copilot_buf then
        print("Copilot terminal not found, creating one...")
        open_copilot_terminal()
      end

      -- Wait for terminal to initialize with retry logic
      vim.defer_fn(function()
        local retry_count = 0
        local max_retries = 10

        local function try_callback()
          retry_count = retry_count + 1
          local cb = find_copilot_buffer()

          if cb then
            local ok, job_id = pcall(vim.api.nvim_buf_get_var, cb, "terminal_job_id")
            if ok and job_id then
              -- Terminal is ready, but if we just created it, wait for Copilot to fully initialize
              if not terminal_already_existed then
                print("Waiting for Copilot to initialize...")
                vim.defer_fn(function()
                  callback(job_id, cb)
                end, 5000)  -- 5 second delay for Copilot to fully start
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

    -- Function to close Copilot terminal
    local function close_copilot_terminal()
      local copilot_buf = find_copilot_buffer()
      if not copilot_buf then
        print("Copilot terminal not found")
        return
      end

      local copilot_win = find_window_for_buffer(copilot_buf)
      if copilot_win then
        -- Close the window
        vim.api.nvim_win_close(copilot_win, false)
      end

      -- Delete the buffer (this will kill the terminal process)
      vim.api.nvim_buf_delete(copilot_buf, { force = true })
      print("Copilot terminal closed")
    end

    -- Function to restart Copilot in the terminal
    local function restart_copilot_terminal()
      local copilot_buf = find_copilot_buffer()
      if not copilot_buf then
        print("Copilot terminal not found, creating new one...")
        open_copilot_terminal()
        return
      end

      -- Get the job ID for the terminal
      local job_id = vim.api.nvim_buf_get_var(copilot_buf, "terminal_job_id")
      if job_id then
        -- Send Ctrl-C to terminate current process
        vim.fn.chansend(job_id, "\x03")
        -- Wait a brief moment
        vim.defer_fn(function()
          -- Start copilot again
          vim.fn.chansend(job_id, "copilot\n")
        end, 100)
      end

      -- Switch to the terminal window if not already there
      local copilot_win = find_window_for_buffer(copilot_buf)
      if copilot_win then
        vim.api.nvim_set_current_win(copilot_win)
      else
        vim.cmd('split')
        vim.api.nvim_set_current_buf(copilot_buf)
      end

      vim.cmd('startinsert')
      print("Copilot terminal restarted")
    end

    -- Function to toggle Copilot terminal visibility
    local function toggle_copilot_terminal()
      local copilot_buf = find_copilot_buffer()
      if not copilot_buf then
        open_copilot_terminal()
        return
      end

      local copilot_win = find_window_for_buffer(copilot_buf)
      if copilot_win then
        -- Window is visible, hide it
        vim.api.nvim_win_close(copilot_win, false)
      else
        -- Window is hidden, show it
        vim.cmd('split')
        vim.api.nvim_set_current_buf(copilot_buf)
      end
    end

    -- Function to open Copilot terminal in vertical split
    local function open_copilot_terminal_vertical()
      local copilot_buf = find_copilot_buffer()
      local copilot_win = copilot_buf and find_window_for_buffer(copilot_buf) or nil

      if copilot_buf and copilot_win then
        -- Buffer exists and is visible, switch to it
        vim.api.nvim_set_current_win(copilot_win)
      elseif copilot_buf then
        -- Buffer exists but not visible, open it in a new vertical split
        vim.cmd('vsplit')
        vim.api.nvim_set_current_buf(copilot_buf)
      else
        -- Buffer doesn't exist, create new terminal in vertical split
        vim.cmd('vsplit')
        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buf)
        vim.fn.termopen("copilot")
        -- Mark this buffer as the Copilot terminal
        vim.api.nvim_buf_set_var(buf, "is_copilot_terminal", true)
        vim.cmd('startinsert')
      end
    end

    -- Function to clear Copilot terminal screen
    local function clear_copilot_terminal()
      local copilot_buf = find_copilot_buffer()
      if not copilot_buf then
        print("Copilot terminal not found")
        return
      end

      local job_id = vim.api.nvim_buf_get_var(copilot_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "clear\n")
      end
    end

    -- Function to send help command to Copilot
    local function send_copilot_help()
      local copilot_buf = find_copilot_buffer()
      if not copilot_buf then
        print("Copilot terminal not found")
        return
      end

      local job_id = vim.api.nvim_buf_get_var(copilot_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "/help\n")
      end

      -- Switch to the terminal
      local copilot_win = find_window_for_buffer(copilot_buf)
      if copilot_win then
        vim.api.nvim_set_current_win(copilot_win)
      end
    end

    -- Function to exit Copilot
    local function exit_copilot()
      local copilot_buf = find_copilot_buffer()
      if not copilot_buf then
        print("Copilot terminal not found")
        return
      end

      local job_id = vim.api.nvim_buf_get_var(copilot_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "/exit\n")
      end
    end

    -- Function to send selected text to Copilot terminal
    local function send_selection_to_copilot()
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

      with_copilot_terminal(function(job_id, copilot_buf)
        for _, line in ipairs(lines) do
          vim.fn.chansend(job_id, line .. "\n")
        end
        print("Selection sent to Copilot terminal")
      end, function(error_msg)
        print("Failed to send selection: " .. error_msg)
      end)
    end

    -- Function to send current file path to Copilot
    local function send_filepath_to_copilot()
      local filepath = vim.fn.expand("%:p")
      if filepath == "" then
        print("No file in current buffer")
        return
      end

      with_copilot_terminal(function(job_id, copilot_buf)
        vim.fn.chansend(job_id, filepath)
        print("File path sent to Copilot terminal: " .. filepath)
      end, function(error_msg)
        print("Failed to send filepath: " .. error_msg)
      end)
    end

    -- Function to interrupt current Copilot command
    local function interrupt_copilot()
      local copilot_buf = find_copilot_buffer()
      if not copilot_buf then
        print("Copilot terminal not found")
        return
      end

      local job_id = vim.api.nvim_buf_get_var(copilot_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "\x03")
        print("Sent interrupt signal to Copilot")
      end
    end

    -- Function to maximize Copilot terminal window
    local function maximize_copilot_terminal()
      local copilot_buf = find_copilot_buffer()
      if not copilot_buf then
        print("Copilot terminal not found, creating new one...")
        open_copilot_terminal()
        return
      end

      local copilot_win = find_window_for_buffer(copilot_buf)
      if not copilot_win then
        -- If window doesn't exist, create it as maximized
        vim.cmd('tabnew')
        vim.api.nvim_set_current_buf(copilot_buf)
      else
        -- Switch to window and maximize it
        vim.api.nvim_set_current_win(copilot_win)
        vim.cmd('only')
      end
    end

    -- Function to send newline to Copilot
    local function send_newline_to_copilot()
      local copilot_buf = find_copilot_buffer()
      if not copilot_buf then
        print("Copilot terminal not found")
        return
      end

      local job_id = vim.api.nvim_buf_get_var(copilot_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "\n")
      end
    end

    -- Function to open copilot web interface in default web browser
    local function open_copilot_web()
      vim.fn.system("xdg-open https://github.com/features/copilot")
      print("Opening GitHub Copilot page in default browser")
    end

    -- Function to open floating prompt window for Copilot
    local function open_copilot_prompt()
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
        title = " Copilot Prompt ",
        title_pos = "center",
      }

      -- Open the floating window
      local win = vim.api.nvim_open_win(buf, true, opts)

      -- Set buffer options
      vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
      vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

      -- Set window options for text wrapping
      vim.api.nvim_win_set_option(win, "wrap", true)
      vim.api.nvim_win_set_option(win, "linebreak", true)

      -- Mark this buffer as the Copilot prompt window
      vim.api.nvim_buf_set_var(buf, "is_copilot_prompt", true)

      -- Function to close the floating window
      local function close_prompt()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end

      -- Function to submit text to Copilot
      local function submit_to_copilot()
        -- Get all text from the buffer
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local text = table.concat(lines, "\n")

        -- Close the floating window
        close_prompt()

        with_copilot_terminal(function(job_id, copilot_buf)
          -- Send text to Copilot
          vim.fn.chansend(job_id, text)
          vim.fn.chansend(job_id, "\n")

          -- Focus Copilot terminal in normal mode
          local copilot_win = find_window_for_buffer(copilot_buf)
          if copilot_win then
            vim.api.nvim_set_current_win(copilot_win)
          else
            vim.cmd('split')
            vim.api.nvim_set_current_buf(copilot_buf)
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
        callback = submit_to_copilot,
        noremap = true,
        silent = true,
      })

      -- Normal mode: <leader>gx to close
      vim.api.nvim_buf_set_keymap(buf, "n", "<leader>gx", "", {
        callback = close_prompt,
        noremap = true,
        silent = true,
      })

      -- Normal mode: <leader>gs to submit
      vim.api.nvim_buf_set_keymap(buf, "n", "<leader>gs", "", {
        callback = submit_to_copilot,
        noremap = true,
        silent = true,
      })

      -- Start in insert mode
      vim.cmd('startinsert')
    end

    -- Keyboard shortcuts for Copilot terminal
    keymapd("<leader>aa", "Open/Switch to Copilot terminal", open_copilot_terminal)
    keymapd("<leader>ap", "Open Copilot prompt window", open_copilot_prompt)
    ikeymapd("<C-p>", "Open Copilot prompt window", open_copilot_prompt)
    tkeymapd("<C-p>", "Open Copilot prompt window", open_copilot_prompt)
    keymapd("<leader>aq", "Close Copilot terminal", close_copilot_terminal)
    keymapd("<leader>ar", "Restart Copilot in terminal", restart_copilot_terminal)
    keymapd("<leader>at", "Toggle Copilot terminal visibility", toggle_copilot_terminal)
    keymapd("<leader>av", "Open Copilot terminal (vertical split)", open_copilot_terminal_vertical)
    keymapd("<leader>aw", "Open GitHub Copilot page in web browser", open_copilot_web)
    keymapd("<leader>ac", "Clear Copilot terminal screen", clear_copilot_terminal)
    keymapd("<leader>ah", "Send /help to Copilot", send_copilot_help)
    keymapd("<leader>ae", "Exit Copilot terminal", exit_copilot)
    vkeymapd("<leader>as", "Send selection to Copilot", send_selection_to_copilot)
    keymapd("<leader>af", "Send current file path to Copilot", send_filepath_to_copilot)
    keymapd("<leader>ai", "Interrupt Copilot command (Ctrl-C)", interrupt_copilot)
    keymapd("<leader>al", "Maximize Copilot terminal window", maximize_copilot_terminal)
    keymapd("<leader>an", "Send newline to Copilot", send_newline_to_copilot)
  '';
in
{
  inherit name lua;

  packages = with pkgs; [
    github-copilot-cli
  ];
}
