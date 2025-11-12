{ ... }:

{
  config = /*lua*/ ''
    {
      ---@type snacks.scope.Config
      scope = {
        min_size = 5,
        max_size = 20,
        siblings = true,
      },
      -- animate scopes. Enabled by default for Neovim >= 0.10
      -- Works on older versions but has to trigger redraws during animation.
      ---@type snacks.animate.Config|{enabled?: boolean}
      animate = {
        enabled = vim.fn.has("nvim-0.10") == 1,
        easing = "outQuad",
        duration = {
          step = 20, -- ms per step
          total = 300, -- maximum duration
        },
      },
      -- what buffers to dim
      filter = function(buf)
        return vim.g.snacks_dim ~= false and vim.b[buf].snacks_dim ~= false and vim.bo[buf].buftype == ""
      end,
    }
  '';

  keymaps = /*lua*/ ''

    wk.add({
      { "<leader>ec", group = "Explore Code", desc = "Code specific commands for exploring" },
      { "<leader>ecd", group = "Code Dim", desc = "Adjust code by dimming surrounding areas" },
    })
    -- Dim keyboard shortcuts
    local initialized_dim = false
    keymapd("<leader>ecde", "Enable the Dim feature", function()
      if not initialized_dim then
        snacks.dim()
        initialized_dim = true
      end
      snacks.dim.enable()
    end)
    keymapd("<leader>ecdd", "Disable the Dim feature", function()
      snacks.dim.disable()
    end)
  '';
}
