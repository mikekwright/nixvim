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

  vimPackages = with pkgs.vimPlugins; [
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
