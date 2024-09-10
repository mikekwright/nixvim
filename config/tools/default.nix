{ debug, ... }:

let
  #treesitter-ensured-list = debug.traceResult (
  #  builtins.concatStringsSep "," (map (f: "\"${f}\"") treesitter-parsers)
  #);

  tools-setup-lua = /*lua*/ ''

  '';
in
{
  name = "tools";

  imports = [
    ./tree.nix
    ./noice.nix
    ./db-tools.nix
    ./telescope.nix
  ];

  lua = debug.traceResult tools-setup-lua;
}

