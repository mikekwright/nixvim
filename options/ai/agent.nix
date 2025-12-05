{ pkgs, ... }:

let
  name = "ai.agent";

  # Unified AI agent module supporting multiple AI assistants
  # Supports: Claude Code, Copilot CLI
  lua = /*lua*/ ''
    -- AI Agent Configuration Module
    -- This module manages multiple AI agents and provides a unified interface

    -- Available AI agents
    local AI_AGENTS = {
      claude = {
        name = "Claude Code",
        command = "claude",
        marker = "is_claude_terminal"
      },
      copilot = {
        name = "Copilot CLI",
        command = "copilot",
        marker = "is_copilot_terminal"
      }
    }

    -- Global state for current agent
    local current_agent = "claude"  -- default
    local config_file = vim.fn.expand("~/.nvim-ai-config")

    -- Helper function to read JSON config file
    local function read_config()
      local file = io.open(config_file, "r")
      if not file then
        return {}
      end

      local content = file:read("*all")
      file:close()

      if content == "" then
        return {}
      end

      -- Parse JSON
      local ok, config = pcall(vim.fn.json_decode, content)
      if ok then
        return config
      else
        return {}
      end
    end

    -- Helper function to write JSON config file
    local function write_config(config)
      local json = vim.fn.json_encode(config)
      local file = io.open(config_file, "w")
      if file then
        file:write(json)
        file:close()
        return true
      end
      return false
    end

    -- Initialize agent selection from config file
    local function init_agent_config()
      local config = read_config()
      local cwd = vim.fn.getcwd()

      if config[cwd] then
        local agent = config[cwd]
        if AI_AGENTS[agent] then
          current_agent = agent
          print("AI Agent set to: " .. AI_AGENTS[agent].name)
        end
      else
        -- Default to claude if not configured
        current_agent = "claude"
      end
    end

    -- Save current directory's agent preference
    local function save_agent_config(agent)
      local config = read_config()
      local cwd = vim.fn.getcwd()
      config[cwd] = agent

      if write_config(config) then
        current_agent = agent
        print("AI Agent set to: " .. AI_AGENTS[agent].name .. " for " .. cwd)
      else
        print("Failed to save agent configuration")
      end
    end

    -- Function to show agent picker
    local function show_agent_picker()
      local choices = {}
      local agent_keys = {}

      for key, agent in pairs(AI_AGENTS) do
        table.insert(choices, agent.name)
        table.insert(agent_keys, key)
      end

      vim.ui.select(choices, {
        prompt = "Select AI Agent:",
        format_item = function(item)
          return item
        end,
      }, function(choice, idx)
        if choice and idx then
          save_agent_config(agent_keys[idx])
        end
      end)
    end

    -- Get current agent config
    local function get_current_agent()
      return AI_AGENTS[current_agent]
    end

    -- Function to show current agent
    local function show_current_agent()
      local agent = get_current_agent()
      local cwd = vim.fn.getcwd()
      vim.notify("Current AI Agent: " .. agent.name .. " (" .. current_agent .. ")\nWorking Directory: " .. cwd, vim.log.levels.INFO)
    end
    
    -- Helper function to find agent terminal buffer
    local function find_agent_buffer()
      local agent = get_current_agent()
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

    -- Function to open or switch to agent terminal
    function open_agent_terminal()
      local agent = get_current_agent()
      local agent_buf = find_agent_buffer()
      local agent_win = agent_buf and find_window_for_buffer(agent_buf) or nil

      local current_buf = vim.api.nvim_get_current_buf()
      local is_alpha = vim.bo[current_buf].filetype == "alpha"

      if agent_buf and agent_win then
        if is_alpha then
          vim.api.nvim_buf_delete(current_buf, { force = true })
          vim.api.nvim_set_current_win(agent_win)
        else
          vim.api.nvim_set_current_win(agent_win)
        end
      elseif agent_buf then
        if is_alpha then
          vim.api.nvim_set_current_buf(agent_buf)
        else
          vim.cmd('split')
          vim.api.nvim_set_current_buf(agent_buf)
        end
      else
        if is_alpha then
          local buf = vim.api.nvim_create_buf(true, false)
          vim.api.nvim_set_current_buf(buf)
          vim.fn.termopen(agent.command)
          vim.api.nvim_buf_set_var(buf, agent.marker, true)
          vim.cmd('startinsert')
        else
          vim.cmd('split')
          local buf = vim.api.nvim_create_buf(true, false)
          vim.api.nvim_set_current_buf(buf)
          vim.fn.termopen(agent.command)
          vim.api.nvim_buf_set_var(buf, agent.marker, true)
          vim.cmd('startinsert')
        end
      end
    end

    -- Helper function to ensure agent terminal exists and is ready
    local function with_agent_terminal(callback, on_error)
      local agent = get_current_agent()
      local agent_buf = find_agent_buffer()
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
        open_agent_terminal()
      end

      vim.defer_fn(function()
        local retry_count = 0
        local max_retries = 10

        local function try_callback()
          retry_count = retry_count + 1
          local cb = find_agent_buffer()

          if cb then
            local ok, job_id = pcall(vim.api.nvim_buf_get_var, cb, "terminal_job_id")
            if ok and job_id then
              if not terminal_already_existed then
                print("Waiting for " .. agent.name .. " to initialize...")
                vim.defer_fn(function()
                  callback(job_id, cb)
                end, 5000)
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

    -- Function to close agent terminal
    local function close_agent_terminal()
      local agent = get_current_agent()
      local agent_buf = find_agent_buffer()
      if not agent_buf then
        print(agent.name .. " terminal not found")
        return
      end

      local agent_win = find_window_for_buffer(agent_buf)
      if agent_win then
        vim.api.nvim_win_close(agent_win, false)
      end

      vim.api.nvim_buf_delete(agent_buf, { force = true })
      print(agent.name .. " terminal closed")
    end

    -- Function to restart agent in the terminal
    local function restart_agent_terminal()
      local agent = get_current_agent()
      local agent_buf = find_agent_buffer()
      if not agent_buf then
        print(agent.name .. " terminal not found, creating new one...")
        open_agent_terminal()
        return
      end

      local job_id = vim.api.nvim_buf_get_var(agent_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "\x03")
        vim.defer_fn(function()
          vim.fn.chansend(job_id, agent.command .. "\n")
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

    -- Function to toggle agent terminal visibility
    local function toggle_agent_terminal()
      local agent_buf = find_agent_buffer()
      if not agent_buf then
        open_agent_terminal()
        return
      end

      local agent_win = find_window_for_buffer(agent_buf)
      if agent_win then
        vim.api.nvim_win_close(agent_win, false)
      else
        vim.cmd('split')
        vim.api.nvim_set_current_buf(agent_buf)
      end
    end

    -- Function to open agent terminal in vertical split
    local function open_agent_terminal_vertical()
      local agent_buf = find_agent_buffer()
      local agent_win = agent_buf and find_window_for_buffer(agent_buf) or nil

      if agent_buf and agent_win then
        vim.api.nvim_set_current_win(agent_win)
      elseif agent_buf then
        vim.cmd('vsplit')
        vim.api.nvim_set_current_buf(agent_buf)
      else
        vim.cmd('vsplit')
        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buf)
        local agent = get_current_agent()
        vim.fn.termopen(agent.command)
        vim.api.nvim_buf_set_var(buf, agent.marker, true)
        vim.cmd('startinsert')
      end
    end

    -- Function to clear agent terminal screen
    local function clear_agent_terminal()
      local agent = get_current_agent()
      local agent_buf = find_agent_buffer()
      if not agent_buf then
        print(agent.name .. " terminal not found")
        return
      end

      local job_id = vim.api.nvim_buf_get_var(agent_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "clear\n")
      end
    end

    -- Function to send help command to agent
    local function send_agent_help()
      local agent = get_current_agent()
      local agent_buf = find_agent_buffer()
      if not agent_buf then
        print(agent.name .. " terminal not found")
        return
      end

      local job_id = vim.api.nvim_buf_get_var(agent_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "/help\n")
      end

      local agent_win = find_window_for_buffer(agent_buf)
      if agent_win then
        vim.api.nvim_set_current_win(agent_win)
      end
    end

    -- Function to exit agent
    local function exit_agent()
      local agent = get_current_agent()
      local agent_buf = find_agent_buffer()
      if not agent_buf then
        print(agent.name .. " terminal not found")
        return
      end

      local job_id = vim.api.nvim_buf_get_var(agent_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "/exit\n")
      end
    end

    -- Function to send selected text to agent terminal
    local function send_selection_to_agent()
      local start_pos = vim.fn.getpos("'<")
      local end_pos = vim.fn.getpos("'>")
      local lines = vim.fn.getline(start_pos[2], end_pos[2])

      if #lines == 0 then
        print("No text selected")
        return
      end

      if #lines == 1 then
        lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
      else
        lines[1] = string.sub(lines[1], start_pos[3])
        lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
      end

      with_agent_terminal(function(job_id, agent_buf)
        for _, line in ipairs(lines) do
          vim.fn.chansend(job_id, line .. "\n")
        end
        local agent = get_current_agent()
        print("Selection sent to " .. agent.name .. " terminal")
      end, function(error_msg)
        print("Failed to send selection: " .. error_msg)
      end)
    end

    -- Function to send current file path to agent
    local function send_filepath_to_agent()
      local filepath = vim.fn.expand("%:p")
      if filepath == "" then
        print("No file in current buffer")
        return
      end

      with_agent_terminal(function(job_id, agent_buf)
        vim.fn.chansend(job_id, filepath)
        local agent = get_current_agent()
        print("File path sent to " .. agent.name .. " terminal: " .. filepath)
      end, function(error_msg)
        print("Failed to send filepath: " .. error_msg)
      end)
    end

    -- Function to interrupt current agent command
    local function interrupt_agent()
      local agent = get_current_agent()
      local agent_buf = find_agent_buffer()
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

    -- Function to maximize agent terminal window
    local function maximize_agent_terminal()
      local agent = get_current_agent()
      local agent_buf = find_agent_buffer()
      if not agent_buf then
        print(agent.name .. " terminal not found, creating new one...")
        open_agent_terminal()
        return
      end

      local agent_win = find_window_for_buffer(agent_buf)
      if not agent_win then
        vim.cmd('tabnew')
        vim.api.nvim_set_current_buf(agent_buf)
      else
        vim.api.nvim_set_current_win(agent_win)
        vim.cmd('only')
      end
    end

    -- Function to send newline to agent
    local function send_newline_to_agent()
      local agent = get_current_agent()
      local agent_buf = find_agent_buffer()
      if not agent_buf then
        print(agent.name .. " terminal not found")
        return
      end

      local job_id = vim.api.nvim_buf_get_var(agent_buf, "terminal_job_id")
      if job_id then
        vim.fn.chansend(job_id, "\n")
      end
    end

    -- Function to open agent web interface
    local function open_agent_web()
      local agent = get_current_agent()
      if current_agent == "claude" then
        vim.fn.system("xdg-open https://claude.ai")
        print("Opening claude.ai in default browser")
      elseif current_agent == "copilot" then
        vim.fn.system("xdg-open https://github.com/features/copilot")
        print("Opening GitHub Copilot page in default browser")
      end
    end

    -- Function to open floating prompt window for agent
    local function open_agent_prompt()
      local agent = get_current_agent()
      local buf = vim.api.nvim_create_buf(false, true)

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
        title = " " .. agent.name .. " Prompt ",
        title_pos = "center",
      }

      local win = vim.api.nvim_open_win(buf, true, opts)

      vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
      vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

      vim.api.nvim_win_set_option(win, "wrap", true)
      vim.api.nvim_win_set_option(win, "linebreak", true)

      vim.api.nvim_buf_set_var(buf, "is_agent_prompt", true)

      local function close_prompt()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end

      local function submit_to_agent()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local text = table.concat(lines, "\n")

        close_prompt()

        with_agent_terminal(function(job_id, agent_buf)
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

      vim.api.nvim_buf_set_keymap(buf, "i", "<C-x>", "", {
        callback = close_prompt,
        noremap = true,
        silent = true,
      })

      vim.api.nvim_buf_set_keymap(buf, "i", "<C-s>", "", {
        callback = submit_to_agent,
        noremap = true,
        silent = true,
      })

      vim.api.nvim_buf_set_keymap(buf, "n", "<leader>ax", "", {
        callback = close_prompt,
        noremap = true,
        silent = true,
      })

      vim.api.nvim_buf_set_keymap(buf, "n", "<leader>as", "", {
        callback = submit_to_agent,
        noremap = true,
        silent = true,
      })

      vim.cmd('startinsert')
    end

    -- Register agent prompt completion disable check
    register_completion_disable_check(function()
      local ok, is_agent_prompt = pcall(vim.api.nvim_buf_get_var, 0, "is_agent_prompt")
      return ok and is_agent_prompt
    end, "AI Agent prompt window")

    -- Initialize agent configuration on startup
    init_agent_config()

    -- Register dashboard action (shows current agent)
    register_dashboard_action("c", "AI Agent", ":lua open_agent_terminal()<CR>")

    -- Keyboard shortcuts for AI agent terminal
    keymapd("<leader>aa", "Open/Switch to AI agent terminal", open_agent_terminal)
    keymapd("<leader>ap", "Open AI agent prompt window", open_agent_prompt)
    ikeymapd("<C-p>", "Open AI agent prompt window", open_agent_prompt)
    tkeymapd("<C-p>", "Open AI agent prompt window", open_agent_prompt)
    keymapd("<leader>aq", "Close AI agent terminal", close_agent_terminal)
    keymapd("<leader>ar", "Restart AI agent in terminal", restart_agent_terminal)
    keymapd("<leader>at", "Toggle AI agent terminal visibility", toggle_agent_terminal)
    keymapd("<leader>av", "Open AI agent terminal (vertical split)", open_agent_terminal_vertical)
    keymapd("<leader>aw", "Open AI agent web interface", open_agent_web)
    keymapd("<leader>ac", "Clear AI agent terminal screen", clear_agent_terminal)
    keymapd("<leader>ah", "Send /help to AI agent", send_agent_help)
    keymapd("<leader>ae", "Exit AI agent terminal", exit_agent)
    keymapd("<leader>as", "Show current AI agent", show_current_agent)
    vkeymapd("<leader>as", "Send selection to AI agent", send_selection_to_agent)
    keymapd("<leader>af", "Send current file path to AI agent", send_filepath_to_agent)
    keymapd("<leader>ai", "Interrupt AI agent command (Ctrl-C)", interrupt_agent)
    keymapd("<leader>al", "Maximize AI agent terminal window", maximize_agent_terminal)
    keymapd("<leader>an", "Send newline to AI agent", send_newline_to_agent)
    keymapd("<leader>ax", "Select AI agent", show_agent_picker)
  '';
in
{
  inherit name lua;

  packages = with pkgs; [
    claude-code
    github-copilot-cli
  ];
}
