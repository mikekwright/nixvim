{ pkgs, ... }:

let
  otterLua = /*lua*/ ''
    require("otter").activate({ "javascript", "python", "rust", "lua"}, true, true, nil) 
  '';
in
{
  extraConfigLua = otterLua;

  extraPlugins = with pkgs.vimPlugins; [
    #{
    #  plugin = otter-nvim;
    #  config = otterLua;
    #    or
    #  config = ''lua require(...)'';
    #}
    otter-nvim
  ];
}

