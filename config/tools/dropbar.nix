{ pkgs, ... }:

let
  # Repo for dropbar plugin https://github.com/Bekaboo/dropbar.nvim
  dropbar-lua = /*lua*/ ''
    dropbar = require('dropbar')
    -- vim.api.nvim_set_hl(0, 'DropBarFileName', { fg = '#FFFFFF', italic = true })
    --
    -- local custom_path = {
    --   get_symbols = function(buff, win, cursor)
    --     local symbols = sources.path.get_symbols(buff, win, cursor)
    --     symbols[#symbols].name_hl = 'DropBarFileName'
    --     if vim.bo[buff].modified then
    --       symbols[#symbols].name = symbols[#symbols].name .. ' [+]'
    --       symbols[#symbols].name_hl = 'DiffAdded'
    --     end
    --     return symbols
    --   end,
    -- }

    -- dropbar.setup({
      -- bar = {
      --   sources = function(buf, _)
      --     if vim.bo[buf].ft == 'markdown' then
      --       return {
      --         custom_path,
      --         sources.markdown,
      --       }
      --     end
      --     if vim.bo[buf].buftype == 'terminal' then
      --       return {
      --         sources.terminal,
      --       }
      --     end
      --     return {
      --       custom_path,
      --       utils.source.fallback {
      --         sources.lsp,
      --         sources.treesitter,
      --       },
      --     }
      --   end,
      -- },
    -- })
  '';
in
{
  lua = dropbar-lua;

  vimPackages = let
    dropbar = pkgs.vimUtils.buildVimPlugin {
      name = "dropbar.nvim";
      src = pkgs.fetchFromGitHub {
        owner = "Bekaboo";
        repo = "dropbar.nvim";
        rev = "v9.0.2";
        sha256 = "O5kosFOe5EYx8ZQafK6M2I83mV/g9/BfUPHumFBE1xM=";
        # rev = "v10.0.0";
        # sha256 = "ipWDstnm5p5S2On0wv9it6BARXuagaWXAm5b8RAX/pc=";
      };
    };
  in [
    dropbar
  ];
}
