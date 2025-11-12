{ includes ? { complete = {}; packages = {}; extensions = {}; ai = {}; } }:

let
  hasOption = option: list1: list2:
    builtins.any (x: x == option) list1 || builtins.any(x: x == option) list2;

    returnDefault = value: let
      valueType = builtins.typeOf value;
    in
      if valueType == "list" then []
      else if valueType == "set" then {}
      else if valueType == "string" then ""
      else null;
in
{
  extensions = option: value: 
    if hasOption option includes.extensions includes.complete
      then value else returnDefault value;

  packages = option: value: 
    if hasOption option includes.packages includes.complete
      then value else returnDefault value;

  ai = option: value: 
    if hasOption option includes.ai includes.complete
      then value else returnDefault value;
}
