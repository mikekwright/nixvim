{ lib, ... }:

let
  complete-includes = import ./complete.nix { inherit lib; };
in
lib.makeIncludes {
  complete = complete-includes.complete ++ [
    "ai.binaries"
    "lsp.haskell"
  ];
}
