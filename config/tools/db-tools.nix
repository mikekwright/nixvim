{ pkgs, ... }:

let
  db-lua-config = /*lua*/ ''
    -- If there are more keys to support look at the plugin documentation
    --   https://github.com/kristijanhusak/vim-dadbod-ui/blob/master/doc/dadbod-ui.txt#L382
    nkeymap("<leader>dd", ":DBUIToggle<CR>")
    nkeymap("<leader>de", "<Plug>(DBUI_ExecuteQuery)")
    nkeymap("<leader>dc", "<Plug>(DBUI_ToggleResultLayout)")
    nkeymap("<leader>dq", "<Plug>(DBUI_Quit)")
    nkeymap("<leader>ds", "<Plug>(DBUI_SaveQuery)")
    nkeymap("<leader>dr", "<Plug>(DBUI_Redraw)")
  '';
in
{
  lua = db-lua-config;

  packages = with pkgs; [
    postgresql  # Need psql for tool
    redis       # Need redis-cli for tool
  ];

  vimPackages = let
    dadbod = pkgs.vimUtils.buildVimPlugin {
      name = "vim-dadbod";
      src = pkgs.fetchFromGitHub {
        owner = "tpope";
        repo = "vim-dadbod";
        rev = "7888cb7164d69783d3dce4e0283decd26b82538b";
        sha256 = "8wnUSYctVn3JeCVz2fdi9qcKi8ZyA4To+xs4WaP6rog=";
      };
    };

    dadbod-ui = pkgs.vimUtils.buildVimPlugin {
      name = "vim-dadbod-ui";
      src = pkgs.fetchFromGitHub {
        owner = "kristijanhusak";
        repo = "vim-dadbod-ui";
        rev = "aa003f514ba0b1250ba0f284f031d011bb9e83e8";
        sha256 = "iymhxKlQ5h/KVH9T/iXYgRgnZlscKfPgIi46BikkOgQ=";
      };
    };

    dadbod-completion = pkgs.vimUtils.buildVimPlugin {
      name = "vim-dadbod-completion";
      src = pkgs.fetchFromGitHub {
        owner = "kristijanhusak";
        repo = "vim-dadbod-completion";
        rev = "880f7e9f2959e567c718d52550f9fae1aa07aa81";
        sha256 = "kci8ksgSRPmRhwTYw7Ya1v4hwPjN4BLFjV6+6YiK1hA=";
      };
    };
  in
  [
    dadbod
    dadbod-ui
    dadbod-completion
  ];
}
