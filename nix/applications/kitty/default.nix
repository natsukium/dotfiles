{ pkgs, ... }:
let
  tmux-prefix = "ctrl+j";
  tmux-compat-keybindings = {
    "${tmux-prefix}>c" = "new_tab";
    "${tmux-prefix}>n" = "next_tab";
    "${tmux-prefix}>p" = "previous_tab";
    "${tmux-prefix}>," = "set_tab_title";
    "${tmux-prefix}>|" = "launch --location=vsplit";
    "${tmux-prefix}>-" = "launch --location=hsplit";
    "${tmux-prefix}>h" = "move_window left";
    "${tmux-prefix}>j" = "move_window down";
    "${tmux-prefix}>k" = "move_window up";
    "${tmux-prefix}>l" = "move_window right";
  };
in
{
  programs = {
    kitty = {
      enable = true;
      settings = {
        "font_family" = "Liga HackGen Console NF";
        "font_size" = 14;
        "hide_window_decorations" = if pkgs.stdenv.isLinux then "yes" else "titlebar-only";
        "tab_bar_edge" = "top";
        "tab_bar_style" = "powerline";
        "scrollback_pager_history_size" = 50;
        "enable_audio_bell" = "no";
        "enabled_layouts" = "Splits,Stack,Tall";
        "macos_option_as_alt" = "yes";
        "confirm_os_window_close" = 0;
      };
      keybindings = { } // tmux-compat-keybindings;
      darwinLaunchOptions = [ "-o allow_remote_control=yes" ];
      shellIntegration.mode = "enabled";
    };

    fish.functions.ssh = {
      body = ''
        if test $TERM = "xterm-kitty"
            kitten ssh $argv
        else
            command ssh $argv
        end
      '';
    };
  };
}
