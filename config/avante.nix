{ pkgs, ... }:

# Avante.nvim is a nvim plugin that supposedly works the same as cursor IDE but focused
#    on neovim instead.
let
  avante_lua = /*lua*/ ''
    require("avante").setup({
      provider = "gemini",

      -- provider = "openai",
      -- openai = {
      --   endpoint = "https://api.openai.com/v1",
      --   model = "gpt-4o", -- your desired model (or use gpt-4o, etc.)
      --   timeout = 30000, -- timeout in milliseconds
      --   temperature = 0, -- adjust if needed
      --   max_tokens = 4096,
      --   -- reasoning_effort = "high" -- only supported for reasoning models (o1, etc.)
      -- },
    })
  '';
in
{
  afterLua = avante_lua;

  vimPackages = let
    avante-plugin = pkgs.vimUtils.buildVimPlugin {
      name = "avante.nvim";
      src = pkgs.fetchFromGitHub {
        owner = "yetone";
        repo = "avante.nvim";
        # v0.0.21 (Feb ~28th, 2025)
        rev = "9c9fadd256d6138d771e17b9ca68905908e16c17";
        sha256 = "XAI+kPUCcWrnHN0SHt6wrQ6gS/F24WGUS9PrtDGyU6A=";
      };
    };
  in
    with pkgs.vimPlugins; [
      avante-plugin
      # Have to use the above plugin as the one under is not working correctly with other plugins
      #avante-nvim

      # These are needed dependencies
      dressing-nvim
      # nui-nvim
      plenary-nvim
      img-clip-nvim
  ];
}
