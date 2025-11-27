{ debug, pkgs, ... }:

let
  name = "tools.electronics";
in
{
  inherit name;

  imports = [
    ./platformio.nix
  ];
}
