{ pkgs, lib, extra-pkgs, ... }:

let
  name = "ai.agent";

  # Import custom opencode wrapper
  opencode-agent = import ./agents/opencode-agent.nix { inherit pkgs extra-pkgs; };

  # Agent configuration list
  # Each agent should have: package, name, description, command
  agents = [
    {
      package = pkgs.claude-code;
      id = "claude";
      name = "Claude Code";
      description = "Anthropic's Claude AI assistant for coding";
      command = "claude";
    }
    {
      package = pkgs.github-copilot-cli;
      id = "copilot";
      name = "Copilot CLI";
      description = "GitHub Copilot command-line interface";
      command = "copilot";
    }
    {
      package = pkgs.cursor-cli;
      id = "cursor";
      name = "Cursor CLI";
      description = "Cursor AI code editor CLI";
      command = "cursor-cli";
    }
    {
      package = pkgs.chatgpt-cli;
      id = "chatgpt";
      name = "ChatGPT CLI";
      description = "OpenAI's ChatGPT command-line interface";
      command = "chatgpt";
    }
    {
      package = pkgs.gemini-cli;
      id = "gemini";
      name = "Gemini CLI";
      description = "Google's Gemini AI command-line interface";
      command = "gemini";
    }
    {
      package = opencode-agent;
      id = "opencode";
      name = "OpenCode";
      description = "OpenCode AI assistant for coding";
      command = "opencode";
    }
  ];

  # Generate Lua agent definitions from Nix agent list
  agentDefsLua = builtins.concatStringsSep ",\n      " (
    map (agent: ''
      ${agent.id} = {
        name = "${agent.name}",
        command = "${agent.command}",
        marker = "is_${agent.id}_terminal"
      }'') agents
  );

  # Unified AI agent module supporting multiple AI assistants
  lua = /*lua*/ ''
    -- AI Agent Configuration Module
    -- This module manages multiple AI agents and provides a unified interface

    -- Available AI agents
    local AI_AGENTS = {
      ${agentDefsLua}
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
        else
          -- Agent configured but not available, fallback to claude
          current_agent = "claude"
          vim.notify(
            string.format("Configured agent '%s' not found or not available.\nFalling back to Claude Code.", agent),
            vim.log.levels.WARN
          )
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
        end
        vim.api.nvim_set_current_win(agent_win)
      elseif agent_buf then
        vim.api.nvim_set_current_buf(agent_buf)
        vim.cmd('startinsert')
      else
        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_set_current_buf(buf)
        vim.fn.termopen(agent.command)
        vim.api.nvim_buf_set_var(buf, agent.marker, true)
        vim.cmd('startinsert')
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

    -- Function to hide agent terminal if visible
    local function hide_agent_terminal()
      local agent = get_current_agent()
      local agent_buf = find_agent_buffer()
      if not agent_buf then
        return
      end

      local agent_win = find_window_for_buffer(agent_buf)
      if agent_win then
        vim.api.nvim_win_close(agent_win, false)
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

    -- Forward declaration for open_agent_prompt
    local open_agent_prompt

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

    -- Function to send selected text to agent prompt
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

    -- Function to send current file path to agent prompt
    local function send_filepath_to_agent()
      local filepath = vim.fn.expand("%:p")
      if filepath == "" then
        print("No file in current buffer")
        return
      end

      -- Insert filepath into prompt window
      insert_text_into_prompt(filepath)
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

    -- Function to open floating prompt window for agent
    open_agent_prompt = function(initial_text)
      local agent = get_current_agent()

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

      -- Only set buffer options for new buffers
      if is_new_buffer then
        vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
        vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
        vim.api.nvim_buf_set_var(buf, "is_agent_prompt", true)
      end

      vim.api.nvim_win_set_option(win, "wrap", true)
      vim.api.nvim_win_set_option(win, "linebreak", true)

      -- If initial text provided, insert it
      if initial_text and initial_text ~= "" then
        -- Split text into lines for proper insertion
        local lines = vim.split(initial_text, "\n", { plain = true })
        vim.api.nvim_put(lines, "c", true, true)
      end

      -- Define callbacks (always set, even for reused buffers, to update closured variables)
      local function close_prompt()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, false)
        end
      end

      local function submit_to_agent()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local text = table.concat(lines, "\n")

        close_prompt()

        -- Delete the buffer after submission
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end

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

      -- Clear existing keymaps and set new ones (for reused buffers)
      pcall(vim.api.nvim_buf_del_keymap, buf, "i", "<C-x>")
      pcall(vim.api.nvim_buf_del_keymap, buf, "i", "<C-s>")
      pcall(vim.api.nvim_buf_del_keymap, buf, "n", "<leader>ax")
      pcall(vim.api.nvim_buf_del_keymap, buf, "n", "<leader>as")

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

    -- Register agent prompt completion disable check
    register_completion_disable_check(function()
      local ok, is_agent_prompt = pcall(vim.api.nvim_buf_get_var, 0, "is_agent_prompt")
      return ok and is_agent_prompt
    end, "AI Agent prompt window")

    -- Initialize agent configuration on startup
    init_agent_config()

    -- Register dashboard action (shows current agent)
    register_dashboard_action("a", "AI Agent", ":lua open_agent_terminal()<CR>")

    -- Keyboard shortcuts for AI agent terminal
    keymapd("<leader>aa", "Open/Switch to AI agent terminal", open_agent_terminal)
    keymapd("<leader>app", "Open AI agent prompt window", open_agent_prompt)
    keymapd("<leader>aph", "Hide AI agent prompt window", hide_agent_prompt)
    ikeymapd("<C-p>", "Open AI agent prompt window", open_agent_prompt)
    tkeymapd("<C-p>", "Open AI agent prompt window", open_agent_prompt)
    keymapd("<leader>ar", "Restart AI agent in terminal", restart_agent_terminal)
    keymapd("<leader>av", "Open AI agent terminal (vertical split)", open_agent_terminal_vertical)
    keymapd("<leader>ah", "Hide AI agent terminal", hide_agent_terminal)
    keymapd("<leader>ae", "Exit AI agent terminal", exit_agent)
    vim.keymap.set("x", "<leader>as", function()
      -- Store a reference to the function to be called after exiting visual mode
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
      vim.schedule(function()
        send_selection_to_agent()
      end)
    end, { silent = true, noremap = true, desc = "Send selection to AI agent" })
    keymapd("<leader>af", "Send current file path to AI agent", send_filepath_to_agent)
    keymapd("<leader>ai", "Interrupt AI agent command (Ctrl-C)", interrupt_agent)
    keymapd("<leader>an", "Send newline to AI agent", send_newline_to_agent)
    keymapd("<leader>ax", "Select AI agent", show_agent_picker)
  '';
in
{
  inherit name lua;

  # Dynamically include all agent packages
  packages = map (agent: agent.package) agents;
}
