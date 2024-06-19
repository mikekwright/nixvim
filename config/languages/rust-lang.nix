{ ... }:

{
  plugins = {
    # Rust Tools configuration (on nixvim)
    #   https://github.com/nix-community/nixvim/blob/main/plugins/languages/rust/rust-tools.nix
    rust-tools = {
      enable = true;
    };

    lsp.servers.rust-analyzer = {
      enable = true;
      installCargo = true;
      installRustc = true;
    };
  };
}

