{ pkgs, ... }:

let
  keysLua = /*lua*/ ''
    local keys = {}
    for k, _ in pairs(${pkgs})
    do
      table.insert(keys, k)
    end
    return keys
  '';
in
{
  lua = keysLua;
}

