{ pkgs, ... }:

let
  jellybeans = pkgs.vimUtils.buildVimPlugin {
    name = "vim-jellybeans";
    src = pkgs.fetchFromGitHub {
      owner = "mikekwright";
      repo = "jellybeans.vim";
      rev = "ef83bf4dc8b3eacffc97bf5c96ab2581b415c9fa";
      sha256 = "X+37Mlyt6+ZwfYlt4ZtdHPXDgcKtiXlUoUPZVb58w/8=";
    };
  };
in
{
  vimPackages = [ jellybeans ];

  lua = /*lua*/ ''
    vim.cmd [[colorscheme jellybeans]]
  '';
}

