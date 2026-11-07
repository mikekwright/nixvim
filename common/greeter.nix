{ pkgs, ... }:

let
  greeterLua = /*lua*/ ''
    -- Initialize global tables for custom greeter buttons; actions registered
    -- with a section name are rendered in their own titled group below the
    -- main buttons
    _G.alpha_custom_buttons = _G.alpha_custom_buttons or {}
    _G.alpha_custom_sections = _G.alpha_custom_sections or {}

    function register_dashboard_action(key, title, action, section)
      local button = {
        key = key,
        title = '  ' .. title,
        action = action
      }

      if section then
        _G.alpha_custom_sections[section] = _G.alpha_custom_sections[section] or {}
        table.insert(_G.alpha_custom_sections[section], button)
      else
        table.insert(_G.alpha_custom_buttons, button)
      end
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

    -- Sort actions by key and build the buttons list for a set of actions
    local function build_buttons(actions)
      table.sort(actions, function(a, b)
        return a.key < b.key
      end)

      local buttons = {}
      for _, custom_btn in ipairs(actions) do
        local btn = dashboard.button(custom_btn.key, custom_btn.title, custom_btn.action)
        table.insert(buttons, btn)
      end
      return buttons
    end

    dashboard.section.buttons.val = build_buttons(_G.alpha_custom_buttons)

    -- Append each named section (sorted by name) below the main buttons
    local section_names = vim.tbl_keys(_G.alpha_custom_sections)
    table.sort(section_names)
    for _, section_name in ipairs(section_names) do
      table.insert(dashboard.config.layout, { type = "padding", val = 1 })
      table.insert(dashboard.config.layout, {
        type = "text",
        val = section_name,
        opts = { hl = "Type", position = "center" },
      })
      table.insert(dashboard.config.layout, { type = "padding", val = 1 })
      table.insert(dashboard.config.layout, {
        type = "group",
        val = build_buttons(_G.alpha_custom_sections[section_name]),
        opts = { spacing = 1 },
      })
    end

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
