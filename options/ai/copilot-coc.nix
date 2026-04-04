{ pkgs, ... }:

let
  name = "ai.copilot-coc";

  lua = /* lua */ ''
    vim.g.copilot_no_tab_map = true
    vim.g.copilot_filetypes = {
      ['*'] = true,
      yaml = false,
      markdown = false,
      svn = false,
      cvs = false,
      hgcommit = false,
    }

    vim.g.coc_global_extensions = vim.g.coc_global_extensions or {}

    if not vim.tbl_contains(vim.g.coc_global_extensions, '@hexuhua/coc-copilot') then
      table.insert(vim.g.coc_global_extensions, '@hexuhua/coc-copilot')
    end

    vim.g.coc_user_config = vim.tbl_deep_extend('force', vim.g.coc_user_config or {}, {
      ['copilot.enable'] = true,
      ['copilot.priority'] = 1000,
      ['copilot.limit'] = 10,
      ['copilot.enablePreselect'] = true,
      ['copilot.timeout'] = 5000,
      ['copilot.showRemainingText'] = true,
    })

    vim.g.coc_copilot_enabled = true

    keymapd('<leader>lec', 'AI: Toggle Copilot', function()
      vim.g.coc_copilot_enabled = not vim.g.coc_copilot_enabled

      local ok = pcall(vim.cmd, vim.g.coc_copilot_enabled and 'Copilot enable' or 'Copilot disable')
      if not ok then
        print('Copilot toggle command is not available yet')
        return
      end

      print('Copilot is now ' .. (vim.g.coc_copilot_enabled and 'enabled' or 'disabled'))
    end)
  '';
in
{
  inherit lua name;

  vimPackages = with pkgs.vimPlugins; [
    copilot-vim
  ];

  packages = with pkgs; [
    nodejs_22
  ];
}
