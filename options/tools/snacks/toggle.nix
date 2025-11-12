{ ... }:

{
  config = /*lua*/ ''
    {
      -- your toggle configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      which_key = true, -- integrate with which-key to show enabled/disabled icons and colors
      notify = true, -- show a notification when toggling
      -- icons for enabled/disabled states
      icon = {
        enabled = " ",
        disabled = " ",
      },
      -- colors for enabled/disabled states
      color = {
        enabled = "green",
        disabled = "yellow",
      },
    }
  '';

  keymaps = /*lua*/ ''
  '';
}
