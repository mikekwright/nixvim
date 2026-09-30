{ ... }:

let
  nixDevelopLua = /*lua*/ ''
    _G.nix_env = {
      state = "none", -- none | inactive | active
      root = nil,
      file = nil,
      activated_with = nil,
      applied_vars = nil,
    }

    local original_path = vim.env.PATH or ""

    -- Variables from the dev shell that should never replace the values of the
    --   running editor session (terminal identity, temp dirs, nix internals).
    local ignored_vars = {
      BASHOPTS = true,
      DISPLAY = true,
      HOME = true,
      LOGNAME = true,
      NIX_BUILD_TOP = true,
      NIX_ENFORCE_PURITY = true,
      NIX_LOG_FD = true,
      NIX_REMOTE = true,
      OLDPWD = true,
      PPID = true,
      PWD = true,
      SHELL = true,
      SHELLOPTS = true,
      SHLVL = true,
      SSL_CERT_FILE = true,
      TEMP = true,
      TEMPDIR = true,
      TERM = true,
      TMP = true,
      TMPDIR = true,
      TZ = true,
      UID = true,
      USER = true,
    }

    local function detect()
      local found = vim.fs.find({ "flake.nix", "shell.nix" }, {
        upward = true,
        path = vim.fn.getcwd(),
      })[1]

      if found then
        _G.nix_env.root = vim.fs.dirname(found)
        _G.nix_env.file = found
      else
        _G.nix_env.root = nil
        _G.nix_env.file = nil
      end

      if vim.env.IN_NIX_SHELL then
        _G.nix_env.state = "active"
      elseif found then
        _G.nix_env.state = "inactive"
      else
        _G.nix_env.state = "none"
      end
    end

    local function merge_paths(...)
      local seen, parts = {}, {}
      for _, path in ipairs({ ... }) do
        if type(path) == "string" then
          for entry in string.gmatch(path, "[^:]+") do
            if not seen[entry] then
              seen[entry] = true
              table.insert(parts, entry)
            end
          end
        end
      end
      return table.concat(parts, ":")
    end

    local function apply_dev_env(variables)
      local applied = {}
      for var_name, var in pairs(variables) do
        if var.type == "exported" and not ignored_vars[var_name] then
          if var_name == "PATH" then
            vim.env.PATH = merge_paths(var.value, original_path, vim.env.NVIM_TOOLS_PATH or "")
          elseif var_name == "XDG_DATA_DIRS" then
            vim.env.XDG_DATA_DIRS = merge_paths(var.value, vim.env.XDG_DATA_DIRS or "")
          else
            vim.env[var_name] = var.value
          end
          table.insert(applied, var_name)
        end
      end
      table.sort(applied)
      return applied
    end

    local function nix_develop(cmd_opts)
      local installable = cmd_opts and cmd_opts.args or ""
      if installable == "" then
        installable = nil
      end

      detect()
      if not _G.nix_env.root then
        vim.notify("Nix: no flake.nix or shell.nix found from " .. vim.fn.getcwd(), vim.log.levels.WARN)
        return
      end

      local cmd = { "nix", "print-dev-env", "--json" }
      if installable then
        table.insert(cmd, installable)
      elseif vim.fs.basename(_G.nix_env.file) == "shell.nix" then
        table.insert(cmd, "--file")
        table.insert(cmd, _G.nix_env.file)
      else
        table.insert(cmd, _G.nix_env.root)
      end

      vim.notify("Nix: loading dev environment (" .. (installable or _G.nix_env.root) .. ") ...", vim.log.levels.INFO)

      vim.system(cmd, { cwd = _G.nix_env.root, text = true }, function(out)
        vim.schedule(function()
          if out.code ~= 0 then
            vim.notify("Nix: print-dev-env failed:\n" .. (out.stderr or "unknown error"), vim.log.levels.ERROR)
            return
          end

          local ok, decoded = pcall(vim.json.decode, out.stdout)
          if not ok or type(decoded) ~= "table" or type(decoded.variables) ~= "table" then
            vim.notify("Nix: could not parse print-dev-env output", vim.log.levels.ERROR)
            return
          end

          local applied = apply_dev_env(decoded.variables)
          _G.nix_env.state = "active"
          _G.nix_env.activated_with = installable or _G.nix_env.root
          _G.nix_env.applied_vars = applied

          vim.notify(table.concat({
            ("Nix: dev environment active (%d variables applied)."):format(#applied),
            "New terminals and agents inherit it.",
            "Existing terminals are unaffected; use :LspRestart for running language servers.",
          }, "\n"), vim.log.levels.INFO)
        end)
      end)
    end

    local function nix_status()
      detect()
      local s = _G.nix_env

      if s.state == "none" then
        vim.notify("Nix: not enabled -- no flake.nix or shell.nix found from " .. vim.fn.getcwd(), vim.log.levels.INFO)
        return
      end

      if s.state == "inactive" then
        vim.notify(table.concat({
          "Nix: not enabled",
          "  project: " .. s.file,
          "  activate with <leader>nd or :NixDevelop",
        }, "\n"), vim.log.levels.WARN)
        return
      end

      local lines = { "Nix: enabled (" .. (vim.env.IN_NIX_SHELL or "?") .. ")" }
      if s.file then
        table.insert(lines, "  project: " .. s.file)
      end
      if vim.env.name then
        table.insert(lines, "  shell name: " .. vim.env.name)
      end
      if s.activated_with then
        table.insert(lines, "  activated in-editor from: " .. s.activated_with)
        table.insert(lines, "  variables applied: " .. tostring(s.applied_vars and #s.applied_vars or 0))
      else
        table.insert(lines, "  inherited from parent shell (launched inside nix develop)")
      end
      local python = vim.fn.exepath("python3")
      if python ~= "" then
        table.insert(lines, "  python3: " .. python)
      end
      vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
    end

    function _G.nix_env.statusline()
      if _G.nix_env.state == "active" then
        return "󱄅 nix"
      elseif _G.nix_env.state == "inactive" then
        return "󱄅 nix off"
      end
      return ""
    end

    function _G.nix_env.statusline_color()
      if _G.nix_env.state == "active" then
        return { fg = "#98be65" }
      elseif _G.nix_env.state == "inactive" then
        return { fg = "#ecbe7b" }
      end
      return {}
    end

    vim.api.nvim_create_user_command("NixDevelop", nix_develop, {
      nargs = "?",
      desc = "Load the project nix dev environment into the running neovim",
    })
    vim.api.nvim_create_user_command("NixStatus", nix_status, {
      desc = "Show the nix environment status",
    })

    vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
      callback = detect,
    })
    detect()

    keymapd("<leader>ns", "Nix: Show environment status", nix_status)
    keymapd("<leader>nd", "Nix: Enter dev environment", function()
      nix_develop()
    end)
  '';
in
{
  common = true;

  lua = nixDevelopLua;
}
