{
  pkgs,
  ...
}: let
  name = "lsp.rust";

  lua = /*lua*/ ''
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
  inherit lua name;

  vimPackages = 
  # let
  #   rustaceanvim = pkgs.vimUtils.buildVimPlugin {
  #     name = "rustaceanvim";
  #     src = pkgs.fetchFromGitHub {
  #       owner = "mrcjkb";
  #       repo = "rustaceanvim";
  #       rev = "v6.9.7";
  #       sha256 = "fQZe0CtY+gXLeuv1+hr2CJwUWK2lvdOFJ9HNlq3brAo=";
  #     };
  #
  #     dependencies = [ pkgs.vimPlugins.neotest ];
  #   };
  # in [
  #   rustaceanvim
  # ];
  with pkgs.vimPlugins; [
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
