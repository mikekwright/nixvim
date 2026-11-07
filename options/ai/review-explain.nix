{ ... }:

let
  name = "ai.review-explain";

  # Thin Neovim launcher for an EXTERNAL review-explain CLI.
  # This flake does not build the CLI, compute diffs, scrape tickets, or call models.
  lua = /*lua*/ ''
    -- Review Explain launcher
    --
    -- Invokes an external `review-explain` (or backend-specific) CLI. Model
    -- selection lives in the backend registry below, not in a single hardcoded
    -- binary. Edit this table to add wrappers or extra argv/env; do not couple
    -- the launcher to one agent product.
    --
    -- backend.args are prepended before the subcommand:
    --   {bin} [...backend.args] start|continue|ask ... --format json
    --
    -- Binary resolution for a backend:
    --   1. backends[name].bin, if set
    --   2. $REVIEW_EXPLAIN_BIN, if set
    --   3. "review-explain"
    -- If the preferred name is not on PATH, the same fallback chain is tried so
    -- a single REVIEW_EXPLAIN_BIN still works when named wrappers are absent.
    --
    -- Default backend on a fresh Neovim session: "default".
    -- Selected backend is stored in vim.g.review_explain_backend (session-global).
    -- CLI session ids are buffer-local (vim.b.review_explain_session). Switching
    -- backends clears every stored session id so continue/ask cannot reuse
    -- another agent's session; run :NixReviewExplain to start again.
    --
    -- Successful steps always update the scratch markdown buffer. When
    -- ai.agent's shared prompt window is already open, the same text is
    -- inserted via insert_text_into_prompt(..., { create = false }). If the
    -- helper or window is missing, the insert is skipped (one notify).

    local backends = {
      -- Edit these entries to match wrappers bundled outside this flake.
      -- args are prepended before start|continue|ask. env is merged into the job.
      ["grok-build"] = {
        bin = "review-explain-grok",
        -- args = { "--adapter", "grok" },
        -- env = { REVIEW_EXPLAIN_MODEL = "grok" },
      },
      ["claude-code"] = {
        bin = "review-explain-claude",
      },
      ["cursor"] = {
        bin = "review-explain-cursor",
      },
      ["default"] = {
        -- bin omitted on purpose: $REVIEW_EXPLAIN_BIN, then review-explain
      },
    }

    local SESSION_VAR = "review_explain_session"
    local BACKEND_VAR = "review_explain_backend"
    local SCRATCH_VAR = "is_review_explain"

    if vim.g.review_explain_backend == nil then
      vim.g.review_explain_backend = "default"
    end

    local function backend_names()
      local names = {}
      for name, _ in pairs(backends) do
        table.insert(names, name)
      end
      table.sort(names)
      return names
    end

    local function current_backend_name()
      local name = vim.g.review_explain_backend
      if type(name) == "string" and backends[name] then
        return name
      end
      return "default"
    end

    local function current_backend()
      return backends[current_backend_name()], current_backend_name()
    end

    local function preferred_bin(backend)
      if type(backend.bin) == "string" and backend.bin ~= "" then
        return backend.bin
      end
      if type(vim.env.REVIEW_EXPLAIN_BIN) == "string" and vim.env.REVIEW_EXPLAIN_BIN ~= "" then
        return vim.env.REVIEW_EXPLAIN_BIN
      end
      return "review-explain"
    end

    local function is_executable(bin)
      return type(bin) == "string" and bin ~= "" and vim.fn.executable(bin) == 1
    end

    local function resolve_bin(backend)
      local preferred = preferred_bin(backend)
      local seen, candidates = {}, {}
      local function add(bin)
        if type(bin) == "string" and bin ~= "" and not seen[bin] then
          seen[bin] = true
          table.insert(candidates, bin)
        end
      end
      add(preferred)
      add(vim.env.REVIEW_EXPLAIN_BIN)
      add("review-explain")
      for _, bin in ipairs(candidates) do
        if is_executable(bin) then
          return bin
        end
      end
      return nil, preferred
    end

    local function missing_bin_message(backend_name, resolved)
      local env_bin = vim.env.REVIEW_EXPLAIN_BIN
      if env_bin == nil or env_bin == "" then
        env_bin = "(unset)"
      end
      return table.concat({
        "review-explain backend '" .. backend_name .. "' is not available.",
        "  resolved binary: " .. tostring(resolved),
        "  REVIEW_EXPLAIN_BIN: " .. env_bin,
        "Install the CLI for this backend, add it to PATH, or set REVIEW_EXPLAIN_BIN.",
      }, "\n")
    end

    local function git_root(bufnr)
      local start_path
      if _G.nixvim_helpers and _G.nixvim_helpers.get_buffer_start_path then
        start_path = _G.nixvim_helpers.get_buffer_start_path(bufnr)
      else
        local name = vim.api.nvim_buf_get_name(bufnr or 0)
        start_path = (name ~= "" and vim.fs.dirname(name)) or vim.fn.getcwd()
      end

      local ok, result = pcall(function()
        return vim.system(
          { "git", "-C", start_path, "rev-parse", "--show-toplevel" },
          { text = true }
        ):wait()
      end)
      if ok and result.code == 0 then
        local root = vim.trim(result.stdout or "")
        if root ~= "" then
          return root
        end
      end
      return vim.fn.getcwd()
    end

    local function current_head(repo)
      local ok, result = pcall(function()
        return vim.system(
          { "git", "-C", repo, "rev-parse", "--abbrev-ref", "HEAD" },
          { text = true }
        ):wait()
      end)
      if ok and result.code == 0 then
        local head = vim.trim(result.stdout or "")
        if head ~= "" then
          return head
        end
      end
      return "HEAD"
    end

    local function job_env(backend)
      if type(backend.env) ~= "table" or next(backend.env) == nil then
        return nil
      end
      local env = vim.fn.environ()
      for key, value in pairs(backend.env) do
        env[key] = value
      end
      return env
    end

    local function build_argv(backend, extra)
      local bin, preferred = resolve_bin(backend)
      if not bin then
        return nil, preferred
      end
      local cmd = { bin }
      if type(backend.args) == "table" then
        for _, arg in ipairs(backend.args) do
          table.insert(cmd, arg)
        end
      end
      for _, arg in ipairs(extra) do
        table.insert(cmd, arg)
      end
      return cmd
    end

    local function clear_all_sessions()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
          pcall(vim.api.nvim_buf_del_var, buf, SESSION_VAR)
          pcall(vim.api.nvim_buf_del_var, buf, BACKEND_VAR)
        end
      end
    end

    local function set_backend(name)
      if not backends[name] then
        vim.notify(
          "Unknown review-explain backend: " .. name
            .. "\navailable: " .. table.concat(backend_names(), ", "),
          vim.log.levels.ERROR
        )
        return
      end
      local previous = current_backend_name()
      vim.g.review_explain_backend = name
      if previous ~= name then
        clear_all_sessions()
        vim.notify(
          "review-explain backend: " .. name
            .. " (was " .. previous .. "). Buffer-local sessions cleared; run :NixReviewExplain to start a new review.",
          vim.log.levels.INFO
        )
      else
        vim.notify("review-explain backend: " .. name, vim.log.levels.INFO)
      end
    end

    local function notify_current_backend()
      vim.notify(
        "review-explain backend: " .. current_backend_name()
          .. "\navailable: " .. table.concat(backend_names(), ", "),
        vim.log.levels.INFO
      )
    end

    local function warning_text(warning)
      if type(warning) == "string" then
        return warning
      end
      if type(warning) == "table" then
        if type(warning.message) == "string" then
          return warning.message
        end
        return vim.inspect(warning)
      end
      return tostring(warning)
    end

    local function find_scratch_buf()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
          local ok, marker = pcall(vim.api.nvim_buf_get_var, buf, SCRATCH_VAR)
          if ok and marker then
            return buf
          end
        end
      end
      return nil
    end

    local function ensure_scratch_buf()
      local buf = find_scratch_buf()
      if buf and vim.api.nvim_buf_is_valid(buf) then
        return buf
      end
      buf = vim.api.nvim_create_buf(true, true)
      pcall(vim.api.nvim_buf_set_name, buf, "review-explain")
      vim.api.nvim_buf_set_var(buf, SCRATCH_VAR, true)
      vim.bo[buf].buftype = "nofile"
      vim.bo[buf].bufhidden = "hide"
      vim.bo[buf].swapfile = false
      vim.bo[buf].filetype = "markdown"
      return buf
    end

    local function show_scratch(buf)
      local win = find_window_for_buffer and find_window_for_buffer(buf) or nil
      if win then
        vim.api.nvim_set_current_win(win)
        return
      end
      local split_ok = pcall(vim.cmd, "botright vsplit")
      if split_ok then
        vim.api.nvim_win_set_buf(0, buf)
      else
        vim.api.nvim_set_current_buf(buf)
      end
    end

    local function notify_prompt_skip()
      if vim.g.review_explain_prompt_skip_notified then
        return
      end
      vim.g.review_explain_prompt_skip_notified = true
      vim.notify(
        "review-explain: shared AI prompt window is not open; step is in the scratch buffer. Open it with <leader>app to also receive steps (submit with <leader>as + agent suffix).",
        vim.log.levels.INFO
      )
    end

    -- Reuse ai.agent's shared prompt insert path. Never open/create the
    -- prompt window from here: if the module is not loaded, the window is
    -- not visible, or the helper is missing, skip and keep the scratch view.
    local function insert_step_into_prompt(text)
      if type(insert_text_into_prompt) ~= "function" then
        notify_prompt_skip()
        return false
      end
      local ok, inserted = pcall(insert_text_into_prompt, text, { create = false })
      if ok and inserted then
        return true
      end
      notify_prompt_skip()
      return false
    end

    local function render_response(response, source_buf, backend_name)
      local lines = {}
      local warnings = response.warnings
      if type(warnings) == "table" then
        for _, warning in ipairs(warnings) do
          local text = warning_text(warning)
          vim.notify(text, vim.log.levels.WARN)
          table.insert(lines, "> " .. text)
        end
        if #warnings > 0 then
          table.insert(lines, "")
        end
      end

      local step = response.step
      if type(step) == "table" then
        if type(step.title) == "string" and step.title ~= "" then
          table.insert(lines, "# " .. step.title)
          table.insert(lines, "")
        end
        if type(step.body) == "string" then
          for _, line in ipairs(vim.split(step.body, "\n", { plain = true })) do
            table.insert(lines, line)
          end
        end
      end

      if #lines == 0 then
        table.insert(lines, "_review-explain returned no step body._")
      end

      local scratch = ensure_scratch_buf()
      vim.bo[scratch].modifiable = true
      vim.api.nvim_buf_set_lines(scratch, 0, -1, false, lines)

      if type(response.session) == "string" and response.session ~= "" then
        if vim.api.nvim_buf_is_valid(source_buf) then
          vim.api.nvim_buf_set_var(source_buf, SESSION_VAR, response.session)
          vim.api.nvim_buf_set_var(source_buf, BACKEND_VAR, backend_name)
        end
        vim.api.nvim_buf_set_var(scratch, SESSION_VAR, response.session)
        vim.api.nvim_buf_set_var(scratch, BACKEND_VAR, backend_name)
      end

      insert_step_into_prompt(table.concat(lines, "\n"))
      show_scratch(scratch)
    end

    local function extract_json(text)
      local trimmed = vim.trim(text or "")
      if trimmed == "" then
        return nil
      end
      local ok, decoded = pcall(vim.json.decode, trimmed)
      if ok and type(decoded) == "table" then
        return decoded
      end
      local first = trimmed:find("{", 1, true)
      local last = trimmed:reverse():find("}", 1, true)
      if first and last then
        last = #trimmed - last + 1
        if last >= first then
          ok, decoded = pcall(vim.json.decode, trimmed:sub(first, last))
          if ok and type(decoded) == "table" then
            return decoded
          end
        end
      end
      return nil
    end

    local function launcher_error(stdout, stderr)
      local parts = { "review-explain launcher error: missing or unparseable JSON." }
      if stdout and vim.trim(stdout) ~= "" then
        table.insert(parts, "stdout:\n" .. stdout)
      end
      if stderr and vim.trim(stderr) ~= "" then
        table.insert(parts, "stderr:\n" .. stderr)
      end
      vim.notify(table.concat(parts, "\n"), vim.log.levels.ERROR)
    end

    local function error_message(response)
      local err = response and response.error
      if type(err) == "table" and type(err.message) == "string" and err.message ~= "" then
        return err.message
      end
      if type(err) == "string" and err ~= "" then
        return err
      end
      return "review-explain failed"
    end

    local function handle_result(out, source_buf, backend_name)
      local decoded = extract_json(out.stdout)
      if not decoded then
        launcher_error(out.stdout, out.stderr)
        return
      end

      if decoded.ok == false then
        vim.notify(error_message(decoded), vim.log.levels.ERROR)
        return
      end

      -- ok=true (including ticket.source == "none" plus a warning): show
      -- warnings, store the session, and render the step. Not a failure.
      render_response(decoded, source_buf, backend_name)
    end

    local function buffer_session(bufnr)
      local ok, session = pcall(vim.api.nvim_buf_get_var, bufnr, SESSION_VAR)
      if ok and type(session) == "string" and session ~= "" then
        return session
      end
      return nil
    end

    local function require_session(bufnr, backend_name)
      local session = buffer_session(bufnr)
      if not session then
        vim.notify(
          "No review-explain session in this buffer. Run :NixReviewExplain first.",
          vim.log.levels.ERROR
        )
        return nil
      end
      local ok, stored_backend = pcall(vim.api.nvim_buf_get_var, bufnr, BACKEND_VAR)
      if ok and stored_backend and stored_backend ~= backend_name then
        vim.notify(
          "This buffer's review-explain session belongs to backend '"
            .. tostring(stored_backend)
            .. "', but '"
            .. backend_name
            .. "' is selected. Run :NixReviewExplain to start a new review.",
          vim.log.levels.ERROR
        )
        return nil
      end
      return session
    end

    local function run_cli(extra, opts)
      local backend, backend_name = current_backend()
      local cmd, preferred = build_argv(backend, extra)
      if not cmd then
        vim.notify(missing_bin_message(backend_name, preferred), vim.log.levels.ERROR)
        return
      end

      local source_buf = vim.api.nvim_get_current_buf()
      local sys_opts = {
        text = true,
        cwd = git_root(source_buf),
        env = job_env(backend),
      }
      if opts and opts.stdin then
        sys_opts.stdin = opts.stdin
      end

      vim.notify("review-explain (" .. backend_name .. "): " .. table.concat(cmd, " "), vim.log.levels.INFO)
      vim.system(cmd, sys_opts, function(out)
        vim.schedule(function()
          handle_result(out, source_buf, backend_name)
        end)
      end)
    end

    local function cmd_start(opts)
      local fargs = opts.fargs or {}
      local n = #fargs
      if n > 3 then
        vim.notify("NixReviewExplain: too many arguments (expected [base] [head] [ticket])", vim.log.levels.ERROR)
        return
      end

      local repo = git_root(0)
      local base, head, ticket
      if n == 0 then
        base, head = "main", current_head(repo)
      elseif n == 1 then
        base, head = "main", fargs[1]
      else
        base, head = fargs[1], fargs[2]
        ticket = fargs[3]
      end

      local extra = {
        "start",
        "--repo", repo,
        "--base", base,
        "--head", head,
      }
      if type(ticket) == "string" and ticket ~= "" then
        table.insert(extra, "--ticket")
        table.insert(extra, ticket)
      end
      table.insert(extra, "--format")
      table.insert(extra, "json")
      run_cli(extra)
    end

    local function cmd_continue()
      local backend_name = current_backend_name()
      local session = require_session(vim.api.nvim_get_current_buf(), backend_name)
      if not session then
        return
      end
      run_cli({
        "continue",
        "--session", session,
        "--format", "json",
      })
    end

    local function cmd_ask(question)
      if type(question) ~= "string" or vim.trim(question) == "" then
        vim.notify("NixReviewAsk: question is required", vim.log.levels.ERROR)
        return
      end
      local backend_name = current_backend_name()
      local session = require_session(vim.api.nvim_get_current_buf(), backend_name)
      if not session then
        return
      end
      run_cli({
        "ask",
        "--session", session,
        "--format", "json",
      }, { stdin = question })
    end

    local function cmd_backend(opts)
      local name = opts.args
      if name == nil or name == "" then
        notify_current_backend()
        return
      end
      set_backend(name)
    end

    vim.api.nvim_create_user_command("NixReviewExplain", cmd_start, {
      nargs = "*",
      desc = "Start a review-explain session (base/head default to main vs current branch)",
    })
    vim.api.nvim_create_user_command("NixReviewContinue", cmd_continue, {
      desc = "Continue the buffer-local review-explain session",
    })
    vim.api.nvim_create_user_command("NixReviewAsk", function(opts)
      local question = opts.args
      if opts.range ~= 0 then
        local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
        question = table.concat(lines, "\n")
      end
      if question == nil or vim.trim(question) == "" then
        vim.ui.input({ prompt = "Review question: " }, function(input)
          if input then
            cmd_ask(input)
          end
        end)
        return
      end
      cmd_ask(question)
    end, {
      nargs = "*",
      range = true,
      desc = "Ask a follow-up in the buffer-local review-explain session",
    })
    vim.api.nvim_create_user_command("NixReviewExplainBackend", cmd_backend, {
      nargs = "?",
      complete = function(arglead)
        local matches = {}
        for _, name in ipairs(backend_names()) do
          if name:sub(1, #arglead) == arglead then
            table.insert(matches, name)
          end
        end
        return matches
      end,
      desc = "Select or show the review-explain backend for this Neovim session",
    })

    wk.add({
      { "<leader>ax", group = "Review Explain", desc = "External review-explain CLI" },
    })
    keymapd("<leader>axs", "Review explain: start", function()
      cmd_start({ fargs = {} })
    end)
    keymapd("<leader>axc", "Review explain: continue", cmd_continue)
    keymapd("<leader>axa", "Review explain: ask", function()
      vim.ui.input({ prompt = "Review question: " }, function(input)
        if input then
          cmd_ask(input)
        end
      end)
    end)
    keymapd("<leader>axb", "Review explain: backend", function()
      vim.ui.select(backend_names(), {
        prompt = "review-explain backend:",
      }, function(choice)
        if choice then
          set_backend(choice)
        end
      end)
    end)
  '';
in
{
  inherit name lua;
}
