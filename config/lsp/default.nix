{ extra-pkgs, ... }:

let
  lsp-config-lua = /*lua*/ ''
    -- For help check out (:h lspconfig-setup)
    local lspconfig = require('lspconfig')

    require('cmp').setup({
      sources = {
        { name = 'nvim_lsp' }
      }
    })

    -- The nvim-cmp almost supports LSP's capabilities so You should advertise it to LSP servers..
    local lsp_cmp_capabilities = require('cmp_nvim_lsp').default_capabilities()
  '';
in
{
  name = "lsp";

  imports = [
    ./rust.nix
  ];

  lua = lsp-config-lua;

  vimPackages =  [
  ] ++ (with extra-pkgs.nvim-lspconfig-pkgs.vimPlugins; [
    nvim-lspconfig
    nvim-cmp
    cmp-nvim-lsp
  ]);
}
