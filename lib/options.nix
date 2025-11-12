{ includes ? { complete = {}; packages = {}; extensions = {}; ai = {}; } }:

let
  hasOption = option: list:
    builtins.any (x: x == option) list;
in

{
  extensions = option: value: 
    let
      defaultReturn = if builtins.isList value then [] else {};
    in
    if hasOption option includes.extensions || hasOption option includes.complete
      then value else defaultReturn;

  packages = option: value: 
    let
      defaultReturn = if builtins.isList value then [] else {};
    in
    if hasOption option includes.packages || hasOption option includes.complete
      then value else defaultReturn;

  ai = option: value: 
    let
      defaultReturn = if builtins.isList value then [] else {};
    in
    if hasOption option includes.ai || hasOption option includes.complete
      then value else defaultReturn;
}
