{ ... }:

let
  luaConfig = /*lua*/ ''
    local function setupRustLang()
      local rt = require('rust-tools')

      rt.setup({
        server = {
          on_attach = function(_, bufnr)
            -- Hover actions
            vim.keymap.set("n", "<C-space>", rt.hover_actions.hover_actions, { buffer = bufnr })
            -- Code action groups
            vim.keymap.set("n", "<Leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
          end,
        },
      })
    end

    setupRustLang()
  '';
in
{
  plugins = {

    #https://github.com/nix-community/nixvim/blob/main/plugins/languages/rust/rust-tools.nix
    rust-tools = {
      enable = true;
    };

    lsp.servers.rust-analyzer = {
      enable = true;
      installCargo = true;
      installRustc = true;
    };
  };

  extraConfigLua = luaConfig;
}

