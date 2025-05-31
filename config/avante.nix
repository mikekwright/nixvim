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

  version = "0.0.23-unstable-2025-05-12";
  src = pkgs.fetchFromGitHub {
    owner = "yetone";
    repo = "avante.nvim";
    rev = "aae4cc4014149e544fb00e78687bcdef8335dd10";
    hash = "sha256-ixJcD8V2rCLCrqE7hHtHfEtQuHeVyIDgyZ1VOY1jmD0=";
  };
  avante-nvim-lib = pkgs.rustPlatform.buildRustPackage {
    pname = "avante-nvim-lib";
    inherit version src;

    useFetchCargoVendor = true;
    cargoHash = "sha256-pmnMoNdaIR0i+4kwW3cf01vDQo39QakTCEG9AXA86ck=";

    nativeBuildInputs = with pkgs; [
      pkg-config
      makeWrapper
      pkgs.perl
    ];

    buildInputs = with pkgs; [
      openssl
    ];

    buildFeatures = [ "luajit" ];

    checkFlags = [
      # Disabled because they access the network.
      "--skip=test_hf"
      "--skip=test_public_url"
      "--skip=test_roundtrip"
      "--skip=test_fetch_md"
    ];
  };
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

      postInstall =
        let
          ext = pkgs.stdenv.hostPlatform.extensions.sharedLibrary;
        in
        ''
          mkdir -p $out/build
          ln -s ${avante-nvim-lib}/lib/libavante_repo_map${ext} $out/build/avante_repo_map${ext}
          ln -s ${avante-nvim-lib}/lib/libavante_templates${ext} $out/build/avante_templates${ext}
          ln -s ${avante-nvim-lib}/lib/libavante_tokenizers${ext} $out/build/avante_tokenizers${ext}
          ln -s ${avante-nvim-lib}/lib/libavante_html2md${ext} $out/build/avante_html2md${ext}
        '';
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
