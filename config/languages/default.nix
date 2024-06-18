{ ... }:

{
  imports = [
    ./lua-lang.nix
    ./rust-lang.nix
    ./typescript-lang.nix
    ./python-lang.nix
  ];

  plugins.lsp.enable = true;
}
