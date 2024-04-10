{ pkgs, ... }:
{
  # Import all your configuration modules here
  imports = [
    ./bufferline.nix
    ./settings.nix
    ./colorschemes
  ];

  #colorschemes.gruvbox.enable = true;

  extraPackages = with pkgs; [
    hello
  ];

  plugins = {
    lualine.enable = true;

    telescope.enable = true;
    oil.enable = true;
    treesitter.enable = true;
    luasnip.enable = true;

    lsp = {
      enable = true;

      servers = {
        tsserver.enable = true;

        lua-ls.enable = true;

        rust-analyzer = {
          enable = true;
          installCargo = true;
          installRustc = true;
        };
      };
    };

    cmp.settings = {
      enable = true;
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
