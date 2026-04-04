{ pkgs, ... }:

let
  name = "lsp.coc.zig";

  zig-vim = pkgs.vimUtils.buildVimPlugin {
    name = "zig.vim";
    src = pkgs.fetchFromGitHub {
      owner = "ziglang";
      repo = "zig.vim";
      rev = "0c100863c7901a79d9c4b7a2092e335cc09337cc";
      sha256 = "sha256-6ARj5+7ceLagu3hJ39NL9WaFSG3Y0PCEbF50/vy5t6w=";
    };
  };

  lua = /* lua */ ''
    _G.coc_merge_config({
      languageserver = {
        zls = {
          command = '${pkgs.zls}/bin/zls',
          filetypes = { 'zig', 'zir' },
          rootPatterns = { 'build.zig', '.git' },
        },
      },
    })
  '';
in
{
  inherit lua name;

  vimPackages = [
    zig-vim
  ]
  ++ (with pkgs.vimPlugins; [
    neotest-zig
  ]);

  packages = with pkgs; [
    zig
    zls
  ];
}
