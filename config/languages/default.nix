{ ... }:

{
  imports = [
    ./rust-lang.nix
    ./python-lang.nix
  ];

  plugins = {
    lsp = {
      enable = true;
      servers = {
        lua-ls.enable = true;
        tsserver.enable = true;
      };
    };

    nix.enable = true;
    zig.enable = true;
  };
}
