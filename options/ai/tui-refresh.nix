{ ... }:

let
  name = "ai.tui-refresh";

  # Recover a garbled in-Neovim TUI (Claude Code, OpenCode, or any other
  # terminal UI) without restarting the job and losing the session.
  #
  # `,cr` is <leader>cr because mapleader / maplocalleader are both comma.
  lua = /*lua*/ ''
    -- TUI refresh: Neovim redraw + SIGWINCH (jobresize bounce) + Ctrl-L.
    -- Does not send Ctrl-C, /exit, or otherwise kill the terminal job.

    local last_agent_term_buf = nil
    local last_term_buf = nil

    local function is_terminal_buf(buf)
      if not buf or not vim.api.nvim_buf_is_valid(buf) then
        return false
      end
      local ok, buftype = pcall(function()
        return vim.bo[buf].buftype
      end)
      return ok and buftype == "terminal"
    end

    -- Agent terminals (Claude Code, OpenCode, and future AI:grok / AI:cursor
    -- style buffers) are marked with is_*_terminal vars and/or an "AI:" name.
    local function is_agent_terminal_buf(buf)
      if not is_terminal_buf(buf) then
        return false
      end

      for _, marker in ipairs({ "is_opencode_terminal", "is_claude_terminal" }) do
        local ok, is_agent = pcall(vim.api.nvim_buf_get_var, buf, marker)
        if ok and is_agent then
          return true
        end
      end

      local ok_vars, vars = pcall(vim.fn.getbufvar, buf, "")
      if ok_vars and type(vars) == "table" then
        for key, value in pairs(vars) do
          if type(key) == "string" and key:match("^is_.+_terminal$") and value then
            return true
          end
        end
      end

      local name = vim.api.nvim_buf_get_name(buf)
      if name:find("AI:", 1, true) then
        return true
      end

      return false
    end

    local function remember_terminal(buf)
      if not is_terminal_buf(buf) then
        return
      end
      last_term_buf = buf
      if is_agent_terminal_buf(buf) then
        last_agent_term_buf = buf
      end
    end

    local function get_job_id(buf)
      local ok, job_id = pcall(vim.api.nvim_buf_get_var, buf, "terminal_job_id")
      if ok and type(job_id) == "number" and job_id > 0 then
        return job_id
      end
      return nil
    end

    local function window_size(win)
      return vim.api.nvim_win_get_width(win), vim.api.nvim_win_get_height(win)
    end

    local function resize_job(job_id, width, height)
      if width < 1 or height < 1 then
        return
      end
      pcall(vim.fn.jobresize, job_id, width, height)
    end

    -- Bounce size by one row so the job sees a real SIGWINCH even when the
    -- window geometry did not change (the usual "TUI is desynced" case).
    local function bounce_jobresize(job_id, width, height)
      local alt_height = height > 1 and (height - 1) or (height + 1)
      resize_job(job_id, width, alt_height)
      vim.defer_fn(function()
        resize_job(job_id, width, height)
        pcall(vim.fn.chansend, job_id, "\x0c")
        pcall(vim.cmd, "redraw!")
      end, 30)
    end

    local function clear_neovim_ui()
      pcall(vim.cmd, "redraw!")
      -- :mode redisplays the mode and clears leftover cmdline/message overlays
      -- such as "Error: Exit code 128" sitting on top of a terminal buffer.
      pcall(vim.cmd, "mode")
      pcall(function()
        require("noice").dismiss({ silent = true })
      end)
      vim.cmd("echo ''")
    end

    local function find_visible_tui_buf()
      local visible_agents = {}
      local visible_terms = {}

      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) then
          local buf = vim.api.nvim_win_get_buf(win)
          if is_terminal_buf(buf) then
            table.insert(visible_terms, buf)
            if is_agent_terminal_buf(buf) then
              table.insert(visible_agents, buf)
            end
          end
        end
      end

      for _, buf in ipairs(visible_agents) do
        if buf == last_agent_term_buf then
          return buf
        end
      end
      if #visible_agents > 0 then
        return visible_agents[1]
      end
      if #visible_terms > 0 then
        return visible_terms[1]
      end
      return nil
    end

    -- Prefer the terminal under the cursor; otherwise the visible AI TUI
    -- (or last-used agent terminal) so a garbled side panel can be fixed
    -- from a code buffer without switching windows.
    local function resolve_tui_buf()
      local current = vim.api.nvim_get_current_buf()
      if is_terminal_buf(current) then
        return current
      end

      local visible = find_visible_tui_buf()
      if visible then
        return visible
      end

      if is_terminal_buf(last_agent_term_buf) then
        return last_agent_term_buf
      end

      if is_terminal_buf(last_term_buf) then
        return last_term_buf
      end

      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if is_agent_terminal_buf(buf) then
          return buf
        end
      end

      return nil
    end

    function refresh_tui()
      clear_neovim_ui()

      local buf = resolve_tui_buf()
      if not buf then
        print("TuiRefresh: no terminal/TUI buffer found")
        return
      end

      remember_terminal(buf)

      local job_id = get_job_id(buf)
      if not job_id then
        print("TuiRefresh: terminal job is not running")
        return
      end

      local win = find_window_for_buffer(buf)
      if win then
        local width, height = window_size(win)
        bounce_jobresize(job_id, width, height)
      else
        -- Hidden buffer: do not invent a size, just ask the app to repaint.
        pcall(vim.fn.chansend, job_id, "\x0c")
      end
    end

    local resize_gen = 0
    local function resize_visible_terminal_jobs()
      resize_gen = resize_gen + 1
      local gen = resize_gen
      vim.defer_fn(function()
        if gen ~= resize_gen then
          return
        end
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_is_valid(win) then
            local buf = vim.api.nvim_win_get_buf(win)
            if is_terminal_buf(buf) then
              local job_id = get_job_id(buf)
              if job_id then
                local width, height = window_size(win)
                resize_job(job_id, width, height)
              end
            end
          end
        end
      end, 50)
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "TermOpen" }, {
      desc = "Remember last TUI/terminal buffer for :TuiRefresh",
      callback = function(args)
        remember_terminal(args.buf)
      end,
    })

    -- Neovim does not always forward a resize to a non-current terminal
    -- window (for example the AI side panel). Push jobresize so the TUI
    -- gets SIGWINCH instead of keeping a stale screen buffer.
    vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
      desc = "Forward window resizes to terminal jobs (SIGWINCH)",
      callback = resize_visible_terminal_jobs,
    })

    vim.api.nvim_create_user_command("TuiRefresh", function()
      refresh_tui()
    end, {
      desc = "Repaint Neovim UI and the active TUI terminal without restarting it",
    })

    pcall(function()
      require("which-key").add({
        { "<leader>c", group = "Clear/UI", mode = { "n", "t" } },
      })
    end)

    keymapd("<leader>cr", "Refresh TUI / terminal display", refresh_tui)
    tkeymapd("<leader>cr", "Refresh TUI / terminal display", refresh_tui)
    -- Extra terminal-mode mapping: comma is leader, so ,cr waits on timeoutlen
    -- after every comma typed into the TUI. <C-w>r matches the existing
    -- terminal <C-w>* maps and does not steal commas.
    tkeymapd("<C-w>r", "Refresh TUI / terminal display", refresh_tui)
  '';
in
{
  inherit name lua;
}
