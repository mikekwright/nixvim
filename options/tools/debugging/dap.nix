{ ... }:

let
  name = "tools.debugging";

  lua = /* lua */ ''
    local dbg = _G.nixvim_debugger
    local dap = require('dap')

    --
    -- DapUI Elements
    --
    local dapui = require('dapui')

    dapui.setup()

    local open_dap_ui = function() dapui.open() end
    local close_dap_ui = function() dapui.close() end
    local toggle_dap_ui = function() dapui.toggle() end

    dap.listeners.before.attach.dapui_config = open_dap_ui 
    dap.listeners.before.launch.dapui_config = open_dap_ui
    dap.listeners.before.event_terminated.dapui_config = close_dap_ui
    dap.listeners.before.event_exited.dapui_config = close_dap_ui
    dap.listeners.before.disconnect.dapui_config = close_dap_ui

    keymapd('<leader>du', 'Debug: Toggle UI', toggle_dap_ui)

    dbg.dap.goto_current_debug_location = function()
      local session = dap.session()
      if not session then
        vim.notify('No active debug session', vim.log.levels.WARN)
        return
      end

      local frame = session.current_frame
      if not frame or not frame.source or not frame.source.path then
        vim.notify('No paused debug location available', vim.log.levels.WARN)
        return
      end

      vim.cmd('edit ' .. vim.fn.fnameescape(frame.source.path))
      vim.api.nvim_win_set_cursor(0, { frame.line or 1, 0 })
      vim.cmd('normal! zz')
    end

    keymapd('<leader>dc', 'Debug: Continue', function()
      if dbg.vscode.run_project_debug_config then
        dbg.vscode.run_project_debug_config()
      elseif dap.session() then
        dap.continue()
      end
    end)
    keymapd('<leader>dr', 'Debug: Run without debugging', function()
      if dbg.vscode.run_project_debug_config then
        dbg.vscode.run_project_debug_config(true)
      end
    end)
    -- keymapd('<leader>db', 'Debug: Toggle breakpoint', function() dap.toggle_breakpoint() end)
    keymapd('<leader>dn', 'Debug: Step over', function() dap.step_over() end)
    keymapd('<leader>di', 'Debug: Step into', function() dap.step_into() end)
    keymapd('<leader>dO', 'Debug: Step out', function() dap.step_out() end)
    keymapd('<leader>dx', 'Debug: Terminate/disconnect', function() if dap.session() then dap.terminate() end end)
    keymapd('<leader>do', 'Debug: Show task output', function()
      vim.cmd('DapTaskOutput')
    end)
    keymapd('<leader>dR', 'Debug: Recent task runs', function()
      vim.cmd('DapTaskRuns')
    end)
    keymapd('<leader>dK', 'Debug: Cancel running tasks', function()
      vim.cmd('DapCancelTask')
    end)
    keymapd('<leader>dg', 'Debug: Show guidance', function()
      dbg.project_dap.show_debug_guidance()
    end)
    keymapd('<leader>dG', 'Debug: Go to current location', dbg.dap.goto_current_debug_location)
    keymapd('<leader>dC', 'Debug: Create project config', function()
      dbg.project_dap.create_project_debug_config()
    end)
  '';
in
{
  inherit lua name;
}
