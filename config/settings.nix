{
  config = {
    globals = {
      #mapleader = ",";
    };
    opts = {
      number = true;          # Show line numbers
      relativenumber = false; # Always start with this option off, but will add key binding to enable if needed

      # All tab details for handling tabs (These are defaults, override per file type)
      tabstop = 2;
      softtabstop = 2;
      shiftwidth = 2;
      expandtab = true;

      smartindent = true;
      showtabline = 2;

      wrap = false;          # Do not wrap text
      breakindent = false;   # This works with wrapping, ignore for now

      # switch buffers without saving
      hidden = true;

      # History is stored at 20 (in vim) this just updates to a larger value
      history = 1000;

      filetype = "on";

      # Enable incremental searching
      #hlsearch = true;
      #incsearch = true;

      # Better splitting
      #splitbelow = true;
      #splitright = true;

      # Enable mouse mode
      #mouse = "a"; # Mouse

      # Enable ignorecase + smartcase for better searching
      ignorecase = true;
      #smartcase = true; # Don't ignore case with capitals
      #grepprg = "rg --vimgrep";
      #grepformat = "%f:%l:%c:%m";

      # Decrease updatetime
      #updatetime = 50; # faster completion (4000ms default)

      # Set completeopt to have a better completion experience
      #completeopt = ["menuone" "noselect" "noinsert"]; # mostly just for cmp

      # Enable persistent undo history
      #swapfile = false;
      #backup = false;
      #undofile = true;

      # Enable 24-bit colors
      #termguicolors = true;

      # Enable the sign column to prevent the screen from jumping
      # signcolumn = "yes";

      # Enable cursor line highlight
      #cursorline = true; # Highlight the line where the cursor is located

      # Set fold settings
      # These options were reccommended by nvim-ufo
      # See: https://github.com/kevinhwang91/nvim-ufo#minimal-configuration
      #foldcolumn = "0";
      #foldlevel = 99;
      #foldlevelstart = 99;
      #foldenable = true;

      # Always keep 8 lines above/below cursor unless at start/end of file
      #scrolloff = 8;

      # Place a column line
      # colorcolumn = "80";

      # Be careful, original config was 10ms which made custom keys not work (way to fast)
      timeoutlen = 1000;

      # Set encoding type
      encoding = "utf-8";
      fileencoding = "utf-8";

      # More space in the neovim command line for displaying messages
      #cmdheight = 0;

      # We don't need to see things like INSERT anymore
      showmode = true;
    };
  };
}
