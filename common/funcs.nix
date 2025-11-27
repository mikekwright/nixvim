{ ... }:

{
  common = true;

  lua = /*lua*/ ''
    -- Helper function to find window displaying a buffer
    function find_window_for_buffer(buf)
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == buf then
          return win
        end
      end
      return nil
    end

  '';
}
