{ pkgs, ... }:

let
  greeterLua = /*lua*/ ''
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

    dashboard.section.buttons.val = {
      dashboard.button("e", "  Open Tree", ":NvimTreeToggle<CR>"),
      dashboard.button("n", "  New file", ":enew<CR>"),
      dashboard.button("s", "  Search", ":Telescope find_files<CR>"),
      dashboard.button("h", "  Recently opened files", ":Telescope oldfiles<CR>"),
      dashboard.button("b", "  Find buffer", ":Telescope buffers<CR>"),
      dashboard.button("p", "  Find project", ":Telescope projects<CR>"),
      dashboard.button("q", " Quit", ":q<CR>")
    }

    require('alpha').setup(dashboard.config)

    vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
  '';
in
{
  lua = greeterLua;

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
