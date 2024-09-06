{ ... }:

let
  commonThemeLua = /*lua*/ ''
    -- optionally enable 24-bit colour
    vim.opt.termguicolors = true

  '';
in
{
  imports = [
    ./jellybeans.nix
  ];

  lua = commonThemeLua; 
}

