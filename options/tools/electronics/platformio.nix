{ pkgs, ... }:

let
  name = "tools.electronics.platformio";

  lua = /*lua*/ ''
    -- PlatformIO configuration
    -- PlatformIO provides embedded development support

    wk.add({
      { "<leader>ep", group = "PlatformIO", desc = "PlatformIO commands" },
    })

    -- Add PlatformIO keymaps here as needed
    -- Example: keymapd("<leader>epb", "PlatformIO: Build", function() vim.cmd("!pio run") end)
  '';
in
{
  inherit lua name;

  vimPackages = [ ];

  packages = with pkgs; [
    platformio
    platformio-core
  ];
}
