{ pkgs, ... }:
let
  inherit (pkgs) lib stdenv;
  tmux-prefix = "ctrl+j";
  tmux-compat-keybindings = {
    "${tmux-prefix}>c" = "new_tab";
    "${tmux-prefix}>n" = "next_tab";
    "${tmux-prefix}>p" = "previous_tab";
    "${tmux-prefix}>," = "set_tab_title";
    "${tmux-prefix}>|" = "launch --location=vsplit";
    "${tmux-prefix}>-" = "launch --location=hsplit";
    "${tmux-prefix}>h" = "neighboring_window left";
    "${tmux-prefix}>j" = "neighboring_window down";
    "${tmux-prefix}>k" = "neighboring_window up";
    "${tmux-prefix}>l" = "neighboring_window right";
  };
in
{
  programs = {
    kitty = {
      enable = true;
      settings =
        let
          moralerspace = family: "'Moralerspace ${family} HWNF'";
          font-features = "'calt liga ss01 ss02 ss03 ss05 ss09'";
        in
        {
          font_family = "family=${moralerspace "Neon"} features=${font-features}";
          bold_font = "family=${moralerspace "Xenon"} features=${font-features}";
          italic_font = "family=${moralerspace "Radon"} features=${font-features}";
          bold_italic_font = "family=${moralerspace "Krypton"} features=${font-features}";
          font_size = 14;
          hide_window_decorations = if stdenv.hostPlatform.isLinux then "yes" else "titlebar-only";
          tab_bar_edge = "top";
          tab_bar_style = "powerline";
          scrollback_pager_history_size = 50;
          enable_audio_bell = "no";
          enabled_layouts = "Splits,Stack,Tall";
          macos_option_as_alt = "yes";
          confirm_os_window_close = 0;
          cursor_trail = 1;
          cursor_blink_interval = "1 ease-out";
          cursor_stop_blinking_after = 20;
          inactive_text_alpha = 0.6;
        }
        // lib.optionalAttrs stdenv.hostPlatform.isDarwin {
          # these effects are available only on macOS or KDE
          background_blur = 10;
          background_opacity = 0.9;
        };
      keybindings = { } // tmux-compat-keybindings;
      darwinLaunchOptions = [ "-o allow_remote_control=yes" ];
      shellIntegration.mode = "enabled";
    };
  };
}
