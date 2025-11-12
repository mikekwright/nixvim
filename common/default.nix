{ ... }:

let
  lua = /*lua*/ ''
    --
    --
    -- (Common section is complete)
    --
    --
  '';
in
{
  inherit lua;

  imports = [
    # This is the starting point for most things
    ./base.nix

    # Keys are critical and whichkey is small enough we should always include
    ./whichkey.nix

    # Theme is always going to be used
    ./theme.nix

    # The common keymaps that should be used regardless of configuration
    ./keymaps.nix

    # The greeter is always an important addition to any good neovim setup
    ./greeter.nix

    # Git is so common in all cases, lets include that by default
    ./git

    # Always include the file tree for viewing
    ./tree.nix
  ];
}
