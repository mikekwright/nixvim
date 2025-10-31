{ pkgs, ... }:

let
  zig-lua = /*lua*/ ''
    lspconfig.zls.setup({
      cmd = { "zls" },
      filetypes = { "zig", "zir" },
      root_dir = lspconfig.util.root_pattern("build.zig", ".git") or vim.loop.cwd,
      single_file_support = true,
    })
  '';
in
{
  lua = zig-lua;

  vimPackages = let
    zig.vim = pkgs.vimUtils.buildVimPlugin {
      name = "zig.vim";
      src = pkgs.fetchFromGitHub {
        owner = "ziglang";
        repo = "zig.vim";
        # Date is Sept 11, 2025
        rev = "0c100863c7901a79d9c4b7a2092e335cc09337cc";
        sha256 = "sha256-6ARj5+7ceLagu3hJ39NL9WaFSG3Y0PCEbF50/vy5t6w=";
      };
    };
  in [
    zig.vim
  ] ++ (with pkgs.vimPlugins; [
    neotest-zig
  ]);

  packages = with pkgs; [
    zig
    zls
  ];
}
