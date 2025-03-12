{ pkgs, ... }:

let
  # nvimTreePlugin = pkgs.vimUtils.buildVimPlugin {
  #   name = "nvim-tree.lua";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "nvim-tree";
  #     repo = "nvim-tree.lua";
  #     rev = "nvim-tree-v1.6.0";
  #     sha256 = "flZphMVMQdwBrJJ+3F5v7WAtnrv1Uwq2UmA+cgGfuQA=";
  #   };
  # };

  nvimTreeLua = /*lua*/ ''
    -- This was pulled from the nvim-tree documentation
    --   https://github.com/nvim-tree/nvim-tree.lua/blob/master/lua/nvim-tree/keymap.lua
    --

    --local treeApi = require("nvim-tree.api")
    --nkeymap("<leader>e", treeApi.tree.toggle)

    require("nvim-web-devicons")

    function nvimTreeOnAttach(bufnr)
      local api = require('nvim-tree.api')

      local function opts(desc)
        return {
          desc = 'nvim-tree: ' .. desc,
          buffer = bufnr,
          noremap = true,
          silent = true,
          nowait = true,
        }
      end

      -- BEGIN_DEFAULT_ON_ATTACH
      vim.keymap.set('n', '<C-]>',   api.tree.change_root_to_node,        opts('CD'))
      vim.keymap.set('n', '<C-e>',   api.node.open.replace_tree_buffer,   opts('Open: In Place'))
      vim.keymap.set('n', '<C-k>',   api.node.show_info_popup,            opts('Info'))
      vim.keymap.set('n', '<C-r>',   api.fs.rename_sub,                   opts('Rename: Omit Filename'))
      vim.keymap.set('n', '<C-t>',   api.node.open.tab,                   opts('Open: New Tab'))
      vim.keymap.set('n', '<C-v>',   api.node.open.vertical,              opts('Open: Vertical Split'))
      vim.keymap.set('n', '<C-x>',   api.node.open.horizontal,            opts('Open: Horizontal Split'))
      vim.keymap.set('n', '<BS>',    api.node.navigate.parent_close,      opts('Close Directory'))
      vim.keymap.set('n', '<CR>',    api.node.open.edit,                  opts('Open'))
      vim.keymap.set('n', '<Tab>',   api.node.open.preview,               opts('Open Preview'))
      vim.keymap.set('n', '>',       api.node.navigate.sibling.next,      opts('Next Sibling'))
      vim.keymap.set('n', '<',       api.node.navigate.sibling.prev,      opts('Previous Sibling'))
      vim.keymap.set('n', '.',       api.node.run.cmd,                    opts('Run Command'))
      vim.keymap.set('n', '-',       api.tree.change_root_to_parent,      opts('Up'))
      vim.keymap.set('n', 'a',       api.fs.create,                       opts('Create File Or Directory'))
      vim.keymap.set('n', 'bd',      api.marks.bulk.delete,               opts('Delete Bookmarked'))
      vim.keymap.set('n', 'bt',      api.marks.bulk.trash,                opts('Trash Bookmarked'))
      vim.keymap.set('n', 'bmv',     api.marks.bulk.move,                 opts('Move Bookmarked'))
      vim.keymap.set('n', 'B',       api.tree.toggle_no_buffer_filter,    opts('Toggle Filter: No Buffer'))
      vim.keymap.set('n', 'c',       api.fs.copy.node,                    opts('Copy'))
      vim.keymap.set('n', 'C',       api.tree.toggle_git_clean_filter,    opts('Toggle Filter: Git Clean'))
      vim.keymap.set('n', '[c',      api.node.navigate.git.prev,          opts('Prev Git'))
      vim.keymap.set('n', ']c',      api.node.navigate.git.next,          opts('Next Git'))
      vim.keymap.set('n', 'd',       api.fs.remove,                       opts('Delete'))
      vim.keymap.set('n', 'D',       api.fs.trash,                        opts('Trash'))
      vim.keymap.set('n', 'E',       api.tree.expand_all,                 opts('Expand All'))
      vim.keymap.set('n', 'e',       api.fs.rename_basename,              opts('Rename: Basename'))
      vim.keymap.set('n', ']e',      api.node.navigate.diagnostics.next,  opts('Next Diagnostic'))
      vim.keymap.set('n', '[e',      api.node.navigate.diagnostics.prev,  opts('Prev Diagnostic'))
      vim.keymap.set('n', 'F',       api.live_filter.clear,               opts('Live Filter: Clear'))
      vim.keymap.set('n', 'f',       api.live_filter.start,               opts('Live Filter: Start'))
      vim.keymap.set('n', 'g?',      api.tree.toggle_help,                opts('Help'))
      vim.keymap.set('n', 'gy',      api.fs.copy.absolute_path,           opts('Copy Absolute Path'))
      vim.keymap.set('n', 'ge',      api.fs.copy.basename,                opts('Copy Basename'))
      vim.keymap.set('n', 'H',       api.tree.toggle_hidden_filter,       opts('Toggle Filter: Dotfiles'))
      vim.keymap.set('n', 'I',       api.tree.toggle_gitignore_filter,    opts('Toggle Filter: Git Ignore'))
      vim.keymap.set('n', 'J',       api.node.navigate.sibling.last,      opts('Last Sibling'))
      vim.keymap.set('n', 'K',       api.node.navigate.sibling.first,     opts('First Sibling'))
      vim.keymap.set('n', 'L',       api.node.open.toggle_group_empty,    opts('Toggle Group Empty'))
      vim.keymap.set('n', 'M',       api.tree.toggle_no_bookmark_filter,  opts('Toggle Filter: No Bookmark'))
      vim.keymap.set('n', 'm',       api.marks.toggle,                    opts('Toggle Bookmark'))
      vim.keymap.set('n', 'o',       api.node.open.edit,                  opts('Open'))
      vim.keymap.set('n', 'O',       api.node.open.no_window_picker,      opts('Open: No Window Picker'))
      vim.keymap.set('n', 'p',       api.fs.paste,                        opts('Paste'))
      vim.keymap.set('n', 'P',       api.node.navigate.parent,            opts('Parent Directory'))
      vim.keymap.set('n', 'q',       api.tree.close,                      opts('Close'))
      vim.keymap.set('n', 'r',       api.fs.rename,                       opts('Rename'))
      vim.keymap.set('n', 'R',       api.tree.reload,                     opts('Refresh'))
      --vim.keymap.set('n', 's',       api.node.run.system,                 opts('Run System'))
      vim.keymap.set('n', 'S',       api.tree.search_node,                opts('Search'))
      vim.keymap.set('n', 'u',       api.fs.rename_full,                  opts('Rename: Full Path'))
      vim.keymap.set('n', 'U',       api.tree.toggle_custom_filter,       opts('Toggle Filter: Hidden'))
      vim.keymap.set('n', 'W',       api.tree.collapse_all,               opts('Collapse'))
      vim.keymap.set('n', 'x',       api.fs.cut,                          opts('Cut'))
      vim.keymap.set('n', 'y',       api.fs.copy.filename,                opts('Copy Name'))
      vim.keymap.set('n', 'Y',       api.fs.copy.relative_path,           opts('Copy Relative Path'))
      vim.keymap.set('n', '<2-LeftMouse>',  api.node.open.edit,           opts('Open'))
      vim.keymap.set('n', '<2-RightMouse>', api.tree.change_root_to_node, opts('CD'))


      vim.keymap.set("n", "s", api.node.open.vertical, {})

    end

    require('nvim-tree').setup({
      actions = {
        open_file = {
          window_picker = {
            enable = false
          }
        }
      },
      update_focused_file = {
        enable = true,
      },
      hijack_directories = {
        auto_open = true
      },
      filters = {
        dotfiles = true
      },
      on_attach = function(bufnr)
        nvimTreeOnAttach(bufnr)
      end
    })

    local function open_nvim_tree(data)
      -- buffer is a directory
      local directory = vim.fn.isdirectory(data.file) == 1

      -- buffer is a [No Name]
      local no_name = data.file == "" and vim.bo[data.buf].buftype == ""

      -- Will automatically open the tree when running setup if startup buffer is a directory,
      -- is empty or is unnamed. nvim-tree window will be focused.
      local open_on_setup = true

      if (directory or no_name) and open_on_setup then
        -- change to the directory
        if directory then
          vim.cmd.cd(data.file)
        end

        -- open the tree
       require("nvim-tree.api").tree.open()
        return
      end

      -- Will automatically open the tree when running setup if startup buffer is a file.
      -- File window will be focused.
      -- File will be found if updateFocusedFile is enabled.
      local open_on_setup_file = false

      -- buffer is a real file on the disk
      local real_file = vim.fn.filereadable(data.file) == 1

      if (real_file or no_name) and open_on_setup_file then

        -- skip ignored filetypes
        local filetype = vim.bo[data.buf].ft
        local ignored_filetypes = {}

        if not vim.tbl_contains(ignored_filetypes, filetype) then
          -- open the tree but don't focus it
          require("nvim-tree.api").tree.toggle({ focus = false })
          return
        end
      end

      -- Will ignore the buffer, when deciding to open the tree on setup.
      local ignore_buffer_on_setup = false
      if ignore_buffer_on_setup then
        require("nvim-tree.api").tree.open()
      end

    end

    local tree_api = require('nvim-tree.api')
    local tree_view = require('nvim-tree.view')

    keymapd("<leader>ee", "Toggle nvim tree", ":NvimTreeToggle<CR>")
    keymapd("<leader>ea", "Toggle hidding dotfiles", tree_api.tree.toggle_enable_filters)
    keymapd("<leader>eh", "Open nvim-tree help", ":help nvim-tree-api<CR>")
    keymapd("<leader>ef", "Show current file in the tree", function()
      if tree_view.is_visible() then
        tree_api.tree.find_file()
      else
        print(vim.fn.expand('%'))
      end
    end)

    keymapd("<leader>et", "Toggle tree follow", function()
      local tree = require('nvim-tree')
      tree.update_focused_file.enable = not tree.update_focused_file.enable
    end)

    -- Run the tree on startup for editor
    --  I removed this in favor of a greeter experience
    --vim.api.nvim_create_autocmd("VimEnter", {callback = open_nvim_tree})

    -- Pulled from redis (https://www.reddit.com/r/neovim/comments/11qz6w1/dynamically_resize_nvimtree/)
    vim.api.nvim_create_autocmd({ "VimResized" }, {
      desc = "Resize nvim-tree if nvim window got resized",

      group = vim.api.nvim_create_augroup("NvimTreeResize", { clear = true }),
      callback = function()
        local percentage = 15

        local ratio = percentage / 100
        local width = math.floor(vim.go.columns * ratio)
        vim.cmd("tabdo NvimTreeResize " .. width)
      end,
    })
  '';
in
{
  lua = nvimTreeLua;

  packages = with pkgs; [
    nerd-fonts.fira-code
  ];

  vimPackages = with pkgs.vimPlugins; [
    nvim-tree-lua

    # Show the icons in the tree (will require a font)
    nvim-web-devicons
  ];
}
