{ pkgs, ... }:

let
  neotestStartLua = /*lua*/ ''
    neotest_adapters = {}
  '';

  neotestEndLua = /*lua*/ ''
    require("neotest").setup({
      adapters = neotest_adapters,
      -- {
      --   require("neotest-python")({
      --     dap = { justMyCode = false },
      --   }),
      --   require("neotest-plenary"),
      --   require("neotest-vim-test")({
      --     ignore_file_types = { "python", "vim", "lua" },
      --   }),
      -- },
    })
  '';
in
{
  lua = neotestStartLua;
  afterLua = neotestEndLua;

  vimPackages = with pkgs.vimPlugins; [
    # This plugin is supposed to make it easier to setup and use tests in conjunction with
    #   the project structures that you are supporting
    # https://github.com/nvim-neotest/neotest
    neotest
  ];
}
