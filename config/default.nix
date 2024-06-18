{ pkgs, ... }:
let
  luaConfig = (builtins.readFile ./lua/main.lua);
in
{
  # Import all your configuration modules here
  imports = [
    ./bufferline.nix
    ./settings.nix
    ./keymaps.nix

    ./colorschemes
    ./plugins
  ];

  extraConfigLua = luaConfig;

  extraPackages = with pkgs; [

  ];

  plugins = {
    lualine.enable = true;

    telescope.enable = true;
    oil.enable = true;
    treesitter.enable = true;
    luasnip.enable = true;

    cmp.settings = {
      enable = false;
      autoEnableSources = true;
      sources = [
        {name = "nvim_lsp";}
        {name = "path";}
        {name = "buffer";}
      ];

      mapping = {
        "<CR>" = "cmp.mapping.confirm({ select = true })";
        "<Tab>" = {
          action = ''
            function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expandable() then
                luasnip.expand()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              elseif check_backspace() then
                fallback()
              else
                fallback()
              end
            end
          '';
          modes = [ "i" "s" ];
        };
      };
    };
  };
}
