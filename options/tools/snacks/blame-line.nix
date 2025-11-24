{ ... }:

{
  config = /*lua*/ ''
    {
      enabled = true,  -- Enable blame_line
      -- optional settings:
      delay = 250,     -- delay before showing blame
      highlight = "Comment",
      position = "end_of_line", -- or "overlay"
    }
      -- enabled = true,
      -- width = 0.6,
      -- height = 0.6,
      -- border = "rounded",
      -- title = " Git Blame ",
      -- title_pos = "center",
      -- ft = "git",
    -- }
  '';

  keymaps = /*lua*/ ''
    keymapd("<leader>lb", "Toggle auto completion", function()
      require("snacks").blame_line.toggle()
    end)
  '';
}
