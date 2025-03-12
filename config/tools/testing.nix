{ pkgs, ... }:

let
  neotest-lua = /*lua*/ ''
    require("neotest").setup({
      adapters = {
        require("neotest-python")({
            -- Extra arguments for nvim-dap configuration
            -- See https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for values
            --dap = { justMyCode = false },
            -- Command line arguments for runner
            -- Can also be a function to return dynamic values
            args = {"--log-level", "DEBUG"},
            -- Runner to use. Will use pytest if available by default.
            -- Can be a function to return dynamic value.
            runner = "pytest",
            -- Custom python path for the runner.
            -- Can be a string or a list of strings.
            -- Can also be a function to return dynamic value.
            -- If not provided, the path will be inferred by checking for 
            -- virtual envs in the local directory and for Pipenev/Poetry configs
            --python = ".venv/bin/python",
            -- Returns if a given file path is a test file.
            -- NB: This function is called a lot so don't perform any heavy tasks within it.
            is_test_file = function(file_path)
              return file_path:match("test_.*%.py$") ~= nil
            end,
            -- !!EXPERIMENTAL!! Enable shelling out to `pytest` to discover test
            -- instances for files containing a parametrize mark (default: false)
            --pytest_discover_instances = true,
        })
      }
    })
  '';
in
{
  lua = neotest-lua;

  # vimPackages = let
  #   neotest-nvim = pkgs.vimUtils.buildVimPlugin {
  #     name = "neotest-nvim";
  #     src = pkgs.fetchFromGitHub {
  #       owner = "nvim-neotest";
  #       repo = "neotest";
  #       rev = "v5.5.0";
  #       sha256 = "ua/fV1zClX97P4aZNPzRuO382D8hm8xe4UaBxa88Hu0=";
  #     };
  #   };
  #   neotest-python = pkgs.vimUtils.buildVimPlugin {
  #     name = "neotest-python";
  #     src = pkgs.fetchFromGitHub {
  #       owner = "nvim-neotest";
  #       repo = "neotest-python";
  #       rev = "72603dfdbaad5695160268cb10531a14cc37236e";  # August 2024
  #       sha256 = "WZ5dH/XgS92fBmFhf/NZcMXmndV/nvHWuKKT/PZlGbU=";
  #     };
  #   };
  # in [
  vimPackages = with pkgs.vimPlugins; [
    neotest
    neotest-python
  ];
}
