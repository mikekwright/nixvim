{ ... }:

let
  luaConfig = (builtins.readFile ./lua/rust-lang.lua);
in
{
  plugins = {

    #https://github.com/nix-community/nixvim/blob/main/plugins/languages/rust/rust-tools.nix

    lsp.servers.rust-analyzer = {
      enable = true;
      installCargo = true;
      installRustc = true;
    };
  };

  extraConfigLua = luaConfig;
}

