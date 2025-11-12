{ ... }:

{
  config = /*lua*/ ''
    {
      ---@type snacks.animate.Duration|number
      duration = 20, -- ms per step
      easing = "linear",
      fps = 60, -- frames per second. Global setting for all animations
    }
  '';

  keymaps = /*lua*/ ''
  '';
}
