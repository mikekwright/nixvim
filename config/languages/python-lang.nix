{ ... }:

{
  # Review the list of available options for this plugin from nixvim
  # documentation: https://github.com/nix-community/nixvim/blob/main/plugins/lsp/language-servers/pylsp.nix

  plugins.lsp.servers = {

    pylyzer.enable = true;
    # This is a rust language server for python
    ruff.enable = true;

    pylsp.settings = {
      enable = true;

      plugins = {
        jedi_completion = {
          enable = true;
        };

        flake8 = {
          enable = true;
          config = {
            ignore = "E501";
          };
        };
      };
    };
  };
}
