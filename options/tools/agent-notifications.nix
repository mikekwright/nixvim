{ pkgs, debug, ... }:

let
  name = "tools.agent-notifications";

  lua = debug.traceResult /*lua*/ ''
    -- Agent Notification Module
    -- Monitors AI agent terminal buffers and sends notifications when they're waiting for input

    -- Configuration (user can override via vim.g.agent_notifications)
    local default_config = {
      enabled = true,
      use_system = true,
      debounce_ms = 2000,
      timeout_ms = 5000,
      check_interval_ms = 1000,
      debug = false,

      patterns = {
        opencode = {
          "Permission required",  -- Permission dialog header
          "Allow once",           -- Permission option
          "Allow always",         -- Permission option
          "Reject",               -- Permission option
          "⇆ select",            -- Selection indicator
          "enter confirm",        -- Confirmation indicator
          "User:",                -- Direct user prompt
          "Waiting for input"     -- Generic waiting message
        },
        claude = {
          "❯",                    -- Selection arrow
          "%d+%.",                -- Numbered menu items (1., 2., 3., etc)
          "Do you want",          -- Common question prompt
          "%(esc%)",              -- (esc) indicator
          "User:",                -- Direct user prompt
          ">>>"                   -- Command prompt
        },
        copilot = { ">>> ", "> " },
        chatgpt = { ">>> ", "User:" },
        gemini = { ">>> ", "User:" },
        cursor = { ">>> ", "User:" },
      }
    }

    -- Global state for monitoring
    local agent_monitors = {}
    local notification_state = {}
    local has_notify_send = nil

    local function get_config()
      local user_config = vim.g.agent_notifications or {}
      return vim.tbl_deep_extend("force", default_config, user_config)
    end

    local function check_notify_send()
      if has_notify_send == nil then
        has_notify_send = vim.fn.executable('notify-send') == 1
      end
      return has_notify_send
    end

    local function send_notification(agent_name, message)
      local config = get_config()

      if not config.enabled then
        return
      end

      if config.use_system and check_notify_send() then
        -- local cmd = string.format(
        --   'notify-send -u critical -t %d -i dialog-information "%s" "%s"',
        --   config.timeout_ms,
        --   vim.fn.shellescape(agent_name),
        --   vim.fn.shellescape(message)
        -- )
        local cmd = string.format(
          'notify-send -u critical -i dialog-information "%s" "%s"',
          vim.fn.shellescape(agent_name),
          vim.fn.shellescape(message)
        )

        vim.fn.system(cmd)
      else
        vim.notify(message, vim.log.levels.INFO, {
          title = agent_name,
          timeout = config.timeout_ms,
        })
      end
    end

    local function get_terminal_last_lines(buf, count)
      if not vim.api.nvim_buf_is_valid(buf) then
        return {}
      end

      local line_count = vim.api.nvim_buf_line_count(buf)
      local start_line = math.max(0, line_count - count)

      local ok, lines = pcall(vim.api.nvim_buf_get_lines, buf, start_line, -1, false)
      if ok then
        return lines
      else
        return {}
      end
    end

    local function get_agent_id_from_name(agent_name)
      local name_lower = agent_name:lower()
      if name_lower:match("claude") then
        return "claude"
      elseif name_lower:match("opencode") then
        return "opencode"
      elseif name_lower:match("copilot") then
        return "copilot"
      elseif name_lower:match("chatgpt") then
        return "chatgpt"
      elseif name_lower:match("gemini") then
        return "gemini"
      elseif name_lower:match("cursor") then
        return "cursor"
      else
        return "opencode"
      end
    end

    local function detect_waiting_pattern(buf, agent_name)
      local config = get_config()
      local agent_id = get_agent_id_from_name(agent_name)
      local patterns = config.patterns[agent_id] or config.patterns.opencode

      local lines = get_terminal_last_lines(buf, 15)

      for _, line in ipairs(lines) do
        for _, pattern in ipairs(patterns) do
          if line:match(pattern) then
            return true, pattern
          end
        end
      end

      return false, nil
    end

    local function is_terminal_idle(buf)
      if not vim.api.nvim_buf_is_valid(buf) then
        return false
      end

      local ok, job_id = pcall(vim.api.nvim_buf_get_var, buf, "terminal_job_id")
      if not ok or not job_id then
        return false
      end

      return true
    end

    local function is_buffer_visible(buf)
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
          return true
        end
      end
      return false
    end

    local function debug_log(msg)
      local config = get_config()
      if config.debug then
        print("[Agent Notif] " .. msg)
      end
    end

    local function check_agent_state(buf, agent_name)
      local config = get_config()

      if not vim.api.nvim_buf_is_valid(buf) then
        debug_log(string.format("Buffer %d invalid, cleaning up", buf))
        if agent_monitors[buf] then
          agent_monitors[buf]:stop()
          agent_monitors[buf] = nil
        end
        notification_state[buf] = nil
        return
      end

      local is_visible = is_buffer_visible(buf)
      debug_log(string.format("Checking buf %d (%s): visible=%s", buf, agent_name, tostring(is_visible)))

      local is_idle = is_terminal_idle(buf)
      debug_log(string.format("Terminal idle check: %s", tostring(is_idle)))

      if not is_idle then
        debug_log("Terminal not idle, resetting state")
        notification_state[buf] = {
          notified = false,
          last_check = vim.loop.now()
        }
        return
      end

      local waiting, pattern = detect_waiting_pattern(buf, agent_name)
      debug_log(string.format("Pattern detection: waiting=%s, pattern=%s", tostring(waiting), tostring(pattern)))

      if waiting then
        local state = notification_state[buf] or { notified = false, last_check = 0 }
        local now = vim.loop.now()
        local time_since_check = now - state.last_check

        debug_log(string.format("State: notified=%s, time_since_check=%dms, debounce=%dms",
          tostring(state.notified), time_since_check, config.debounce_ms))

        if not state.notified and time_since_check >= config.debounce_ms then
          debug_log("SENDING NOTIFICATION!")
          send_notification(agent_name, "Agent is waiting for input")
          notification_state[buf] = {
            notified = true,
            last_check = now,
            pattern = pattern
          }
        elseif not state.notified then
          debug_log(string.format("Waiting for debounce (%dms remaining)", config.debounce_ms - time_since_check))
          notification_state[buf] = {
            notified = false,
            last_check = state.first_detected or now,
            first_detected = state.first_detected or now
          }
        else
          debug_log("Already notified, not sending again")
        end
      else
        debug_log("No waiting pattern detected, resetting state")
        notification_state[buf] = {
          notified = false,
          last_check = vim.loop.now()
        }
      end
    end

    function register_agent_notification_handler(buf, agent_name)
      local config = get_config()

      if not config.enabled then
        return
      end

      if agent_monitors[buf] then
        agent_monitors[buf]:stop()
      end

      notification_state[buf] = {
        notified = false,
        last_check = vim.loop.now()
      }

      local timer = vim.loop.new_timer()
      timer:start(config.check_interval_ms, config.check_interval_ms, vim.schedule_wrap(function()
        check_agent_state(buf, agent_name)
      end))

      agent_monitors[buf] = timer

      vim.api.nvim_create_autocmd("BufDelete", {
        buffer = buf,
        callback = function()
          if agent_monitors[buf] then
            agent_monitors[buf]:stop()
            agent_monitors[buf] = nil
          end
          notification_state[buf] = nil
        end,
      })

      vim.api.nvim_create_autocmd("TermEnter", {
        buffer = buf,
        callback = function()
          notification_state[buf] = {
            notified = false,
            last_check = vim.loop.now()
          }
        end,
      })
    end

    keymapd('<leader>ant', "Toggle agent notifications", function()
      local config = get_config()
      config.enabled = not config.enabled
      vim.g.agent_notifications = config

      if config.enabled then
        print("Agent notifications enabled")
      else
        print("Agent notifications disabled")
      end
    end)

    keymapd('<leader>anD', "Toggle agent notification debug mode", function()
      local config = get_config()
      config.debug = not config.debug
      vim.g.agent_notifications = config

      if config.debug then
        print("Agent notification debug mode ENABLED - watch for [Agent Notif] messages")
      else
        print("Agent notification debug mode DISABLED")
      end
    end)

    keymapd('<leader>ans', "Show agent notification status", function()
      local config = get_config()
      local status_lines = {
        "Agent Notifications Status:",
        "  Enabled: " .. tostring(config.enabled),
        "  Debug: " .. tostring(config.debug),
        "  Use System: " .. tostring(config.use_system),
        "  notify-send available: " .. tostring(check_notify_send()),
        "  Debounce: " .. config.debounce_ms .. "ms",
        "  Check interval: " .. config.check_interval_ms .. "ms",
        "",
        "Monitored buffers:",
      }

      local count = 0
      for buf, timer in pairs(agent_monitors) do
        if vim.api.nvim_buf_is_valid(buf) then
          count = count + 1
          local ok, agent_marker = pcall(vim.api.nvim_buf_get_var, buf, "agent_name")
          local agent = ok and agent_marker or "unknown"
          local state = notification_state[buf] or {}
          table.insert(status_lines, string.format("  Buffer %d (%s): notified=%s",
            buf, agent, tostring(state.notified or false)))
        end
      end

      if count == 0 then
        table.insert(status_lines, "  None")
      end

      print(table.concat(status_lines, "\n"))
    end)

    -- Function to generate debug content for a buffer
    local function generate_debug_content(source_buf)
      local ok, agent_name = pcall(vim.api.nvim_buf_get_var, source_buf, "agent_name")
      if not ok then
        return nil, "Buffer is not an agent terminal"
      end

      -- Get all debug information
      local lines = get_terminal_last_lines(source_buf, 25)
      local config = get_config()
      local agent_id = get_agent_id_from_name(agent_name)
      local patterns = config.patterns[agent_id] or config.patterns.claude
      local is_visible = is_buffer_visible(source_buf)
      local is_idle = is_terminal_idle(source_buf)
      local waiting, matched_pattern = detect_waiting_pattern(source_buf, agent_name)
      local state = notification_state[source_buf]
      local now = vim.loop.now()

      -- Build debug output
      local debug_lines = {
        "╔══════════════════════════════════════════════════════════════════════════════╗",
        "║                    AGENT NOTIFICATION DEBUG VIEWER                           ║",
        "╚══════════════════════════════════════════════════════════════════════════════╝",
        "",
        "=== BUFFER INFORMATION ===",
        "  Buffer ID:           " .. source_buf,
        "  Agent Name:          " .. agent_name,
        "  Agent ID:            " .. agent_id,
        "",
        "=== DETECTION CHECKS ===",
        "  Buffer Valid:        " .. tostring(vim.api.nvim_buf_is_valid(source_buf)),
        "  Buffer Visible:      " .. tostring(is_visible),
        "  Terminal Idle:       " .. tostring(is_idle),
        "  Pattern Detected:    " .. tostring(waiting),
        "  Matched Pattern:     " .. (matched_pattern or "none"),
        "",
        "=== NOTIFICATION STATE ===",
      }

      if state then
        local time_since_check = state.last_check and (now - state.last_check) or 0
        local time_since_first = state.first_detected and (now - state.first_detected) or 0
        table.insert(debug_lines, "  Notified:            " .. tostring(state.notified))
        table.insert(debug_lines, "  Last check:          " .. tostring(state.last_check) .. " (" .. time_since_check .. "ms ago)")
        if state.first_detected then
          table.insert(debug_lines, "  First detected:      " .. tostring(state.first_detected) .. " (" .. time_since_first .. "ms ago)")
        end
        if state.pattern then
          table.insert(debug_lines, "  Detected pattern:    " .. state.pattern)
        end

        if waiting and not state.notified then
          local debounce_remaining = math.max(0, config.debounce_ms - time_since_check)
          if time_since_check >= config.debounce_ms then
            table.insert(debug_lines, "  Status:              ⚠ SHOULD NOTIFY NOW!")
          else
            table.insert(debug_lines, "  Status:              Waiting for debounce (" .. debounce_remaining .. "ms remaining)")
          end
        elseif waiting and state.notified then
          table.insert(debug_lines, "  Status:              Already notified (waiting for state change)")
        else
          table.insert(debug_lines, "  Status:              Not waiting")
        end
      else
        table.insert(debug_lines, "  State:               Not initialized")
      end

      table.insert(debug_lines, "")
      table.insert(debug_lines, "=== CONFIGURATION ===")
      table.insert(debug_lines, "  Enabled:             " .. tostring(config.enabled))
      table.insert(debug_lines, "  Debug Mode:          " .. tostring(config.debug))
      table.insert(debug_lines, "  Use System:          " .. tostring(config.use_system))
      table.insert(debug_lines, "  notify-send:         " .. tostring(check_notify_send()))
      table.insert(debug_lines, "  Debounce:            " .. config.debounce_ms .. "ms")
      table.insert(debug_lines, "  Check Interval:      " .. config.check_interval_ms .. "ms")

      table.insert(debug_lines, "")
      table.insert(debug_lines, "=== PATTERNS TO MATCH ===")
      for i, pattern in ipairs(patterns) do
        table.insert(debug_lines, string.format("  %d. %s", i, pattern))
      end

      table.insert(debug_lines, "")
      table.insert(debug_lines, "=== TERMINAL CONTENT (Last 25 lines) ===")
      table.insert(debug_lines, "")

      if #lines == 0 then
        table.insert(debug_lines, "  (No terminal content)")
      else
        for i, line in ipairs(lines) do
          local matched_patterns = {}
          for _, pattern in ipairs(patterns) do
            if line:match(pattern) then
              table.insert(matched_patterns, pattern)
            end
          end

          if #matched_patterns > 0 then
            table.insert(debug_lines, string.format("  %3d [✓ MATCH] %s", i, line))
            for _, pat in ipairs(matched_patterns) do
              table.insert(debug_lines, string.format("      └─ Pattern: %s", pat))
            end
          else
            table.insert(debug_lines, string.format("  %3d [       ] %s", i, line))
          end
        end
      end

      table.insert(debug_lines, "")
      table.insert(debug_lines, "=== INSTRUCTIONS ===")
      table.insert(debug_lines, "  Press 'q' to close this buffer")
      table.insert(debug_lines, "  Press 'r' to refresh the debug view")
      table.insert(debug_lines, "")

      return debug_lines
    end

    -- Function to refresh debug buffer content
    local function refresh_debug_buffer(debug_buf)
      local ok, source_buf = pcall(vim.api.nvim_buf_get_var, debug_buf, "source_agent_buffer")
      if not ok or not vim.api.nvim_buf_is_valid(source_buf) then
        print("Source buffer no longer valid")
        return
      end

      local debug_lines, err = generate_debug_content(source_buf)
      if not debug_lines then
        print("Error: " .. (err or "unknown"))
        return
      end

      -- Update buffer content
      vim.api.nvim_buf_set_option(debug_buf, "modifiable", true)
      vim.api.nvim_buf_set_lines(debug_buf, 0, -1, false, debug_lines)
      vim.api.nvim_buf_set_option(debug_buf, "modifiable", false)
    end

    keymapd('<leader>and', "Debug agent terminal output (current buffer)", function()
      local source_buf = vim.api.nvim_get_current_buf()

      local debug_lines, err = generate_debug_content(source_buf)
      if not debug_lines then
        print(err or "Error generating debug content")
        return
      end

      -- Create or reuse debug buffer
      local debug_buf = nil
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
          local buf_name = vim.api.nvim_buf_get_name(buf)
          if buf_name:match("Agent%-Notification%-Debug") then
            debug_buf = buf
            break
          end
        end
      end

      if not debug_buf then
        debug_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(debug_buf, "Agent-Notification-Debug")
      end

      -- Set buffer content
      vim.api.nvim_buf_set_option(debug_buf, "modifiable", true)
      vim.api.nvim_buf_set_lines(debug_buf, 0, -1, false, debug_lines)
      vim.api.nvim_buf_set_option(debug_buf, "modifiable", false)
      vim.api.nvim_buf_set_option(debug_buf, "buftype", "nofile")
      vim.api.nvim_buf_set_option(debug_buf, "bufhidden", "hide")
      vim.api.nvim_buf_set_option(debug_buf, "filetype", "agent-debug")

      -- Store reference to source buffer
      vim.api.nvim_buf_set_var(debug_buf, "source_agent_buffer", source_buf)

      -- Open in split
      vim.cmd("split")
      vim.api.nvim_win_set_buf(0, debug_buf)

      -- Set up keymaps in debug buffer
      vim.api.nvim_buf_set_keymap(debug_buf, "n", "q", ":close<CR>", {
        noremap = true,
        silent = true,
        desc = "Close debug buffer"
      })

      vim.api.nvim_buf_set_keymap(debug_buf, "n", "r", "", {
        noremap = true,
        silent = true,
        callback = function()
          refresh_debug_buffer(debug_buf)
        end,
        desc = "Refresh debug view"
      })
    end)
  '';
in
{
  inherit name lua;

  packages = with pkgs; [
    libnotify
  ];
}
