{ ... }:

let
  name = "ai";
in
{
  inherit name;

  imports = [
    # There is a big change in the tooling, I think a terminal solution is actually going to provide better support
    #   but we will have to see.
    # ./avante.nix
    ./claude.nix
  ];
}
