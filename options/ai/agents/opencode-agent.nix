{ pkgs, extra-pkgs, ... }:

let
  opencodeConfig = {
    keybinds = {
      messages_page_up = "ctrl+shift+k";
      messages_page_down = "ctrl+shift+j";
      messages_half_page_up = "ctrl+k";
      messages_half_page_down = "ctrl+j";

      session_interrupt = "escape";
      session_child_cycle = "<leader>right";
      session_child_cycle_reverse = "<leader>left";

      input_submit = "return";
      input_newline = "shift+return,ctrl+return,alt+return";

      input_move_left = "none";
      input_move_right = "none";
      input_move_up = "none";
      input_move_down = "none";

      history_previous = "up";
      history_next = "down";

      leader = "ctrl+a";

      agent_list = "<leader>a";
      agent_cycle = "<leader>shift+a";
      command_list = "<leader>p";
      
      messages_copy = "<leader>y";
      messages_undo = "<leader>u";
      messages_redo = "<leader>r";

      session_export = "<leader>x";
      session_new = "<leader>n";
      session_list = "<leader>l";
      status_view = "<leader>s";

      app_exit = "<leader>q";
      editor_open = "<leader>e";
      theme_list = "<leader>t";
      sidebar_toggle = "<leader>b";

      messages_toggle_conceal = "<leader>h";

      scrollbar_toggle = "none";
      username_toggle = "none";
      session_fork = "none";
      session_rename = "none";
      session_share = "none";
      session_unshare = "none";

      session_timeline = "none";
      session_compact = "none";
      
      messages_first = "none";
      messages_last = "none";
      messages_last_user = "none";

      tool_details = "none";

      model_list = "<leader>m";
      model_cycle_recent = "none";
      model_cycle_recent_reverse = "none";
      model_cycle_favorite = "none";
      model_cycle_favorite_reverse = "none";

      agent_cycle_reverse = "none";

      input_clear = "none";
      input_paste = "none";
      
      input_select_left = "shift+left";
      input_select_right = "shift+right";
      input_select_up = "shift+up";
      input_select_down = "shift+down";

      # All none

      input_line_home = "none";
      input_line_end = "none";
      input_select_line_home = "none";
      input_select_line_end = "none";
      input_visual_line_home = "none";
      input_visual_line_end = "none";
      input_select_visual_line_home = "none";
      input_select_visual_line_end = "none";
      input_buffer_home = "none";
      input_buffer_end = "none";
      input_select_buffer_home = "none";
      input_select_buffer_end = "none";
      input_delete_line = "none";
      input_delete_to_line_end = "none";
      input_delete_to_line_start = "none";
      input_backspace = "none";
      input_delete = "none";
      input_undo = "none";
      input_redo = "none";
      input_word_forward = "none";
      input_word_backward = "none";
      input_select_word_forward = "none";
      input_select_word_backward = "none";
      input_delete_word_forward = "none";
      input_delete_word_backward = "none";
      
      terminal_suspend = "none";
      terminal_title_toggle = "none";
    };
    "$schema" = "https://opencode.ai/config.json";
  };

  configFile = pkgs.writeText "opencode-nvim-config.json" (builtins.toJSON opencodeConfig);

  opencode-wrapper = pkgs.writeShellScriptBin "opencode" ''
    export OPENCODE_CONFIG="${configFile}"
    export OPENCODE_NO_UPDATE_CHECK="1"
    export OPENCODE_LOG_LEVEL="info"
    # export OPENCODE_CONFIG="/tmp/test.json"

    exec ${extra-pkgs.opencode.opencode}/bin/opencode "$@"
  '';
in
  opencode-wrapper
