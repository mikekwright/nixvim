{ ... }:

let
  name = "ai";
in
{
  inherit name;

  imports = [
    ./avante.nix
  ];
}
