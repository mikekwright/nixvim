{ pkgs, ... }:

let
  db-lua-config = /*lua*/ ''
  wk.add({
    { "<leader>ed", group = "Database", desc = "View database details" },
  })

    -- If there are more keys to support look at the plugin documentation
    --   https://github.com/kristijanhusak/vim-dadbod-ui/blob/master/doc/dadbod-ui.txt#L382
    nkeymap("<leader>edd", ":DBUIToggle<CR>")
    nkeymap("<leader>ede", "<Plug>(DBUI_ExecuteQuery)")
    nkeymap("<leader>edc", "<Plug>(DBUI_ToggleResultLayout)")
    nkeymap("<leader>edq", "<Plug>(DBUI_Quit)")
    nkeymap("<leader>eds", "<Plug>(DBUI_SaveQuery)")
    nkeymap("<leader>edr", "<Plug>(DBUI_Redraw)")
  '';
in
{
  lua = db-lua-config;

  packages = with pkgs; [
    postgresql  # Need psql for tool
    redis       # Need redis-cli for tool
  ];

  vimPackages = let
    # dadbod = pkgs.vimUtils.buildVimPlugin {
    #   name = "vim-dadbod";
    #   src = pkgs.fetchFromGitHub {
    #     owner = "tpope";
    #     repo = "vim-dadbod";
    #     rev = "7888cb7164d69783d3dce4e0283decd26b82538b";
    #     sha256 = "8wnUSYctVn3JeCVz2fdi9qcKi8ZyA4To+xs4WaP6rog=";
    #   };
    # };

    #
    # You can easily test a connection in dadbod just by using echo on the function db#adapter#dispatch like so
    #    :echo db#adapter#dispatch("redis://user:pass@localhost:6383/0", "interactive")
    #

    dadbod = pkgs.vimUtils.buildVimPlugin {
      name = "vim-dadbod";
      src = pkgs.fetchFromGitHub {
        owner = "mikekwright";
        repo = "vim-dadbod";
        rev = "fcb7c2e1775df2433b197d15cc7d82dda5bf0601";
        sha256 = "Dem8kxmzWurRiAtHQgASIREUK2zIcFIi5nKv5i9WOfM=";
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
    
    vim-dispatch = pkgs.vimUtils.buildVimPlugin {
      name = "vim-dispatch";
      src = pkgs.fetchFromGitHub {
        owner = "tpope";
        repo = "vim-dispatch";
        rev = "a2ff28abdb2d89725192db5b8562977d392a4d3f";
        sha256 = "+92jco3btPAHWbVKL0kXycL4Inji3Wi0LtfQ5vXe6B8=";
      };
    };
  in
  [
    vim-dispatch
    dadbod
    dadbod-ui
    dadbod-completion
  ];
}
