{ pkgs, ... }:

let
  nvimHelloWorld = pkgs.vimUtils.buildVimPlugin {
    name = "nvim-hello-world";
    src = pkgs.fetchFromGitHub {
      owner = "jw3126";
      repo = "nvim-hello-world";
      rev = "4128bd645bcac1d2e4bbbfca014f10e0b7f1b1b3";
      sha256 = "36vs8tL4YMiBBWXaFO1ynEl82fg8ja/6kiSN44I3XQs=";
    };
  };

  helloLua = /*lua*/ ''
    require('hello-world').greet()
  '';
in
{
  vimPackages = [ nvimHelloWorld ];

  lua = helloLua;
}

