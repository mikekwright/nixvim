{ pkgs, debug, extra-pkgs, ... }:

let
  treesitter-parsers = [
    "arduino"
    "angular"
    "bash"
    "c"
    "c_sharp"
    "css"
    "csv"
    "vim"
    "vimdoc"
    "regex"
    "lua"
    "markdown"
    "markdown_inline"
  ];

  treesitter-ensured-list = debug.traceResult (
    builtins.concatStringsSep "," (map (f: "\"${f}\"") treesitter-parsers)
  );

  tools-setup-lua = /*lua*/ ''
    require('nvim-treesitter.configs').setup {
      -- Parsers can be set using the nix package management
      auto_install = false,

      ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
      -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

      highlight = {
        enable = true,

        -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
        -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
        -- the name of the parser)
        -- list of language that will be disabled
        --disable = { "c", "rust" },
        -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
        disable = function(lang, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
                return true
            end
        end,

        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = false,
      },
    }


    require("noice").setup({
      lsp = {
        signature = false,
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
        },
      },
      -- you can enable a preset for easier configuration
      presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = false, -- add a border to hover docs and signature help
      },
    })
  '';
in
{
  name = "tools";

  imports = [
    ./tree.nix
    ./db-tools.nix
  ];

  lua = debug.traceResult tools-setup-lua;

  vimPackages = let
    # Noice replaces the cmdline, messages and some popup stuff
    #   https://github.com/folke/noice.nvim 
    noice-nvim = pkgs.vimUtils.buildVimPlugin {
      name = "noice.nvim";
      src = pkgs.fetchFromGitHub {
        owner = "folke";
        repo = "noice.nvim";
        rev = "448bb9c524a7601035449210838e374a30153172";  # 4.5.0
        sha256 = "86oWl3XGuuVhaWVe6egjc7Mt8Pp7qpTMJ2EZiNlztt8=";
      };
    }; 
  in [ 
    noice-nvim
  ]  ++ (with pkgs.vimPlugins; [
    nvim-notify
  ]) ++ [
    extra-pkgs.nvim-treesitter-pkgs.vimPlugins.nvim-treesitter
  ] ++ (map (p: extra-pkgs.nvim-treesitter-pkgs.vimPlugins.nvim-treesitter-parsers.${p}) treesitter-parsers);
}

