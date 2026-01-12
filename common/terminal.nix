{ ... }:

let
  terminalLua = /*lua*/ ''
    _G.shared_term_buf = nil

    local function is_buffer_valid(bufnr)
      return bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_option(bufnr, 'buftype') == 'terminal'
    end

    local function find_terminal_window()
      if not is_buffer_valid(_G.shared_term_buf) then
        return nil
      end

      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == _G.shared_term_buf then
          return win
        end
      end
      return nil
    end

    local function open_or_switch_terminal_fullscreen()
      local term_win = find_terminal_window()

      if term_win then
        vim.api.nvim_set_current_win(term_win)
        vim.cmd("startinsert")
      elseif is_buffer_valid(_G.shared_term_buf) then
        vim.api.nvim_set_current_buf(_G.shared_term_buf)
        vim.cmd("startinsert")
      else
        vim.cmd("terminal")
        _G.shared_term_buf = vim.api.nvim_get_current_buf()
        vim.cmd("startinsert")
      end
    end

    local function open_or_show_terminal_split()
      local term_win = find_terminal_window()

      if term_win then
        vim.api.nvim_set_current_win(term_win)
        vim.cmd("startinsert")
      elseif is_buffer_valid(_G.shared_term_buf) then
        vim.cmd("new")
        vim.api.nvim_set_current_buf(_G.shared_term_buf)
        vim.cmd("startinsert")
      else
        vim.cmd("new")
        vim.cmd("terminal")
        _G.shared_term_buf = vim.api.nvim_get_current_buf()
        vim.cmd("startinsert")
      end
    end

    local function open_or_show_terminal_vscode()
      local term_win = find_terminal_window()

      if term_win then
        vim.api.nvim_set_current_win(term_win)
        vim.cmd("startinsert")
      elseif is_buffer_valid(_G.shared_term_buf) then
        local height = math.floor(vim.o.lines * 0.25)
        vim.cmd("botright split")
        vim.api.nvim_win_set_height(0, height)
        vim.api.nvim_set_current_buf(_G.shared_term_buf)
        vim.cmd("startinsert")
      else
        local height = math.floor(vim.o.lines * 0.25)
        vim.cmd("botright split")
        vim.api.nvim_win_set_height(0, height)
        vim.cmd("terminal")
        _G.shared_term_buf = vim.api.nvim_get_current_buf()
        vim.cmd("startinsert")
      end
    end

    local function escape_terminal_and_switch()
      vim.cmd("stopinsert")
      vim.schedule(function()
        open_or_switch_terminal_fullscreen()
      end)
    end

    keymap("<C-t>", open_or_switch_terminal_fullscreen)
    keymap("<C-w>t", open_or_switch_terminal_fullscreen)
    tkeymap("<C-w>t", escape_terminal_and_switch)
    keymapd("<leader>tt", "Open terminal", open_or_switch_terminal_fullscreen)
    keymapd("<leader>tn", "Open terminal (split)", open_or_show_terminal_split)
    keymapd("<leader>tv", "Open terminal (VSCode style)", open_or_show_terminal_vscode)
  '';
in
{
  common = true;

  lua = terminalLua;
}
