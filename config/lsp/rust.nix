{
  pkgs,
  ...
}: let
  rustAnalyzerLua =
    /*
    lua
    */
    ''
      vim.g.rustaceanvim = {
        server = {
          on_attach = function(client, bufnr)
            -- Your on_attach function here
          end,
          default_settings = {
            -- rust-analyzer language server configuration
            ['rust-analyzer'] = {
              cmd = { "${pkgs.rust-analyzer}/bin/rust-analyzer" },
              cargo = {
                allFeatures = true,
              },
            },
          },
        },
      }
    '';
in {
  lua = rustAnalyzerLua;

  vimPackages = let
    rustaceanvim = pkgs.vimUtils.buildVimPlugin {
      name = "rustaceanvim";
      src = pkgs.fetchFromGitHub {
        owner = "mrcjkb";
        repo = "rustaceanvim";
        rev = "v5.10.1";
        sha256 = "fQZe0CtY+gXLeuv1+hr2CJwUWK2lvdOFJ9HNlq3brAo=";
      };
    };
  in [
    rustaceanvim
  ];

  packages = with pkgs; [
    # This is the lsp server, but requires access to cargo and rustc
    rust-analyzer

    rustc
    #rustup
    cargo
  ];
}
