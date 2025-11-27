{ pkgs, ... }:

let
  greeterLua = /*lua*/ ''
    -- Initialize global table for custom greeter buttons
    _G.alpha_custom_buttons = _G.alpha_custom_buttons or {}

    function register_dashboard_action(key, title, action)
      table.insert(_G.alpha_custom_buttons, {
        key = key,
        title = '  ' .. title,
        action = action
      })
    end

    -- Register default dashboard actions
    register_dashboard_action("e", "Open Tree", ":NvimTreeToggle<CR>")
    register_dashboard_action("n", "New file", ":enew<CR>")
    register_dashboard_action("q", "Quit", ":q<CR>")
  '';

  greeterAfterLua = /*lua*/ ''
    -- Setup alpha dashboard with all registered buttons
    local greeter = require('alpha')
    local dashboard = require('alpha.themes.dashboard')

    dashboard.section.header.val = {
      "███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
      "████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
      "██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
      "██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
      "██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
      "╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
    }

    -- Sort actions by key before building buttons list
    table.sort(_G.alpha_custom_buttons, function(a, b)
      return a.key < b.key
    end)

    -- Build buttons list from all registered actions
    local buttons = {}
    for _, custom_btn in ipairs(_G.alpha_custom_buttons) do
      local btn = dashboard.button(custom_btn.key, custom_btn.title, custom_btn.action)
      table.insert(buttons, btn)
    end
    dashboard.section.buttons.val = buttons

    require('alpha').setup(dashboard.config)
    vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
  '';
in
{
  common = true;

  lua = greeterLua;
  afterLua = greeterAfterLua;

  vimPackages = let
    alpha-nvim = pkgs.vimUtils.buildVimPlugin {
      name = "nvim-alpha";
      src = pkgs.fetchFromGitHub {
        owner = "goolord";
        repo = "alpha-nvim";
        rev = "b6f4129302db197a7249e67a90de3f2b676de13e";
        sha256 = "gvPEmjM36Z7Q8K83/0ZVLN6J/2mDfEZJ7cW1u+FWf/8=";
      };
    };
  in [
    alpha-nvim
  ];
}
