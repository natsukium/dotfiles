{
  lib,
  config,
  inputs,
  ...
}:
with lib;
let
  inherit (config.colorScheme.palette)
    base00
    base01
    base02
    base03
    base04
    base05
    base06
    base07
    base08
    base09
    base0A
    base0B
    base0C
    base0D
    base0E
    base0F
    ;
  inherit (inputs.nix-colors.lib-core) conversions;
  splitRGB =
    with builtins;
    s:
    map (x: substring x 2 s) [
      0
      2
      4
    ];
  shellRGB = color: concatStringsSep "/" (splitRGB color);
  cfg = config.base16;
in
{
  options.base16 = {
    enable = mkEnableOption "";
    bat = mkOption {
      type = types.bool;
      default = true;
    };
    btop = mkOption {
      type = types.bool;
      default = config.programs.btop.enable;
    };
    fish = mkOption {
      type = types.bool;
      default = true;
    };
    fuzzel = mkOption {
      type = types.bool;
      default = true;
    };
    fzf = mkOption {
      type = types.bool;
      default = true;
    };
    hyprland = mkOption {
      type = types.bool;
      default = true;
    };
    kitty = mkOption {
      type = types.bool;
      default = true;
    };
    mako = mkOption {
      type = types.bool;
      default = true;
    };
    qutebrowser = mkOption {
      type = types.bool;
      default = true;
    };
    wofi = mkOption {
      type = types.bool;
      default = true;
    };
  };
  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.bat { programs.bat.config.theme = "base16-256"; })
    (mkIf cfg.btop {
      xdg.configFile."btop/themes/base16.theme".text = ''
        theme[main_bg]="#${base00}"
        theme[main_fg]="#${base04}"
        theme[title]="#${base07}"
        theme[hi_fg]="#${base0F}"
        theme[selected_bg]="#${base03}"
        theme[selected_fg]="#${base06}"
        theme[inactive_fg]="#${base03}"
        theme[proc_misc]="#${base0F}"
        theme[cpu_box]="#${base03}"
        theme[mem_box]="#${base03}"
        theme[net_box]="#${base03}"
        theme[proc_box]="#${base03}"
        theme[div_line]="#${base03}"
        theme[temp_start]="#${base0D}"
        theme[temp_mid]="#${base0C}"
        theme[temp_end]="#${base06}"
        theme[cpu_start]="#${base0D}"
        theme[cpu_mid]="#${base0C}"
        theme[cpu_end]="#${base06}"
        theme[free_start]="#${base0D}"
        theme[free_mid]="#${base0C}"
        theme[free_end]="#${base06}"
        theme[cached_start]="#${base0D}"
        theme[cached_mid]="#${base0C}"
        theme[cached_end]="#${base06}"
        theme[available_start]="#${base0D}"
        theme[available_mid]="#${base0C}"
        theme[available_end]="#${base06}"
        theme[used_start]="#${base0D}"
        theme[used_mid]="#${base0C}"
        theme[used_end]="#${base06}"
        theme[download_start]="#${base0D}"
        theme[download_mid]="#${base0C}"
        theme[download_end]="#${base06}"
        theme[upload_start]="#${base0D}"
        theme[upload_mid]="#${base0C}"
        theme[upload_end]="#${base06}"
      '';
      programs.btop.settings = {
        color_theme = "base16";
      };
    })
    (mkIf cfg.fish {
      programs.fish.interactiveShellInit = ''
        if test -n "$TMUX"
          # Tell tmux to pass the escape sequences through
          # (Source: http://permalink.gmane.org/gmane.comp.terminal-emulators.tmux.user/1324)
          function put_template; printf '\033Ptmux;\033\033]4;%d;rgb:%s\033\033\\\033\\' $argv; end;
          function put_template_var; printf '\033Ptmux;\033\033]%d;rgb:%s\033\033\\\033\\' $argv; end;
          function put_template_custom; printf '\033Ptmux;\033\033]%s%s\033\033\\\033\\' $argv; end;
        else if string match 'screen*' $TERM
          # GNU screen (screen, screen-256color, screen-256color-bce)
          function put_template; printf '\033P\033]4;%d;rgb:%s\007\033\\' $argv; end;
          function put_template_var; printf '\033P\033]%d;rgb:%s\007\033\\' $argv; end;
          function put_template_custom; printf '\033P\033]%s%s\007\033\\' $argv; end;
        else if string match 'linux*' $TERM
          function put_template; test $argv[1] -lt 16 && printf "\e]P%x%s" $argv[1] (echo $argv[2] | sed 's/\///g'); end;
          function put_template_var; true; end;
          function put_template_custom; true; end;
        else
          function put_template; printf '\033]4;%d;rgb:%s\033\\' $argv; end;
          function put_template_var; printf '\033]%d;rgb:%s\033\\' $argv; end;
          function put_template_custom; printf '\033]%s%s\033\\' $argv; end;
        end

        # 16 color space
        put_template 0  ${shellRGB base00}
        put_template 1  ${shellRGB base08}
        put_template 2  ${shellRGB base0B}
        put_template 3  ${shellRGB base0A}
        put_template 4  ${shellRGB base0D}
        put_template 5  ${shellRGB base0E}
        put_template 6  ${shellRGB base0C}
        put_template 7  ${shellRGB base05}
        put_template 8  ${shellRGB base03}
        put_template 9  ${shellRGB base08}
        put_template 10 ${shellRGB base0B}
        put_template 11 ${shellRGB base0A}
        put_template 12 ${shellRGB base0D}
        put_template 13 ${shellRGB base0E}
        put_template 14 ${shellRGB base0C}
        put_template 15 ${shellRGB base07}

        # 256 color space
        put_template 16 ${shellRGB base09}
        put_template 17 ${shellRGB base0F}
        put_template 18 ${shellRGB base01}
        put_template 19 ${shellRGB base02}
        put_template 20 ${shellRGB base04}
        put_template 21 ${shellRGB base06}

        # foreground / background / cursor color
        put_template_var 10 ${base05}
        if [ "$BASE16_SHELL_SET_BACKGROUND" != false ]
          put_template_var 11 ${base00}
          if string match 'rxvt*' $TERM # [ "$\{TERM%%-*}" = "rxvt" ]
            put_template_var 708 ${base00} # internal border (rxvt)
          end
        end
        put_template_custom 12 ";7" # cursor (reverse video)

        # set syntax highlighting colors
        set -U fish_color_autosuggestion ${base03} brblack
        set -U fish_color_cancel -r
        set -U fish_color_command ${base0D} blue
        set -U fish_color_comment ${base03} brblack
        set -U fish_color_cwd ${base0B} green
        set -U fish_color_cwd_root ${base08} red
        set -U fish_color_end ${base0C} cyan
        set -U fish_color_error ${base08} red
        set -U fish_color_escape ${base0C} cyan
        set -U fish_color_history_current --bold
        set -U fish_color_host normal
        set -U fish_color_match --background=brblue
        set -U fish_color_normal normal
        set -U fish_color_operator ${base0C} cyan
        set -U fish_color_param ${base06} cyan
        set -U fish_color_quote ${base0B} green
        set -U fish_color_redirection ${base0A} yellow
        set -U fish_color_search_match ${base0A} bryellow --background=brblack
        set -U fish_color_selection ${base05} white --bold --background=brblack
        set -U fish_color_status ${base08} red
        set -U fish_color_user ${base0B} brgreen
        set -U fish_color_valid_path --underline
        set -U fish_pager_color_completion normal
        set -U fish_pager_color_description ${base0A} yellow
        set -U fish_pager_color_prefix ${base05} white --bold --underline
        set -U fish_pager_color_progress ${base07} brwhite --background=cyan

        # clean up
        functions -e put_template put_template_var put_template_custom
      '';
    })
    (mkIf cfg.fuzzel {
      programs.fuzzel.settings = {
        colors = {
          background = "${base00}e6";
          text = "${base05}ff";
          match = "${base0D}ff";
          selection = "${base03}ff";
          selection-text = "${base06}ff";
          selection-match = "${base0D}ff";
          border = "${base05}ff";
        };
      };
    })
    (mkIf cfg.fzf {
      programs.fzf.colors = {
        bg = "#${base00}";
        "bg+" = "#${base01}";
        fg = "#${base04}";
        "fg+" = "#${base06}";
        hl = "#${base0D}";
        "hl+" = "#${base0D}";
        spinner = "#${base0C}";
        header = "#${base0D}";
        info = "#${base0A}";
        pointer = "#${base0C}";
        marker = "#${base0C}";
        prompt = "#${base0A}";
      };
    })
    (mkIf cfg.hyprland {
      wayland.windowManager.hyprland.settings = {
        decoration."col.shadow" = "rgba(${conversions.hexToRGBString ", " base00}, 1)";
        general = {
          "col.active_border" = "rgb(${base0D})";
          "col.inactive_border" = "rgb(${base03})";
        };
      };
    })
    (mkIf cfg.kitty {
      programs.kitty.settings = {
        background = "#${base00}";
        foreground = "#${base05}";
        selection_background = "#${base05}";
        selection_foreground = "#${base00}";
        url_color = "#${base04}";
        cursor = "#${base05}";
        active_border_color = "#${base03}";
        inactive_border_color = "#${base01}";
        active_tab_background = "#${base00}";
        active_tab_foreground = "#${base05}";
        inactive_tab_background = "#${base01}";
        inactive_tab_foreground = "#${base04}";
        tab_bar_background = "#${base01}";

        # normal
        color0 = "#${base00}";
        color1 = "#${base08}";
        color2 = "#${base0B}";
        color3 = "#${base0A}";
        color4 = "#${base0D}";
        color5 = "#${base0E}";
        color6 = "#${base0C}";
        color7 = "#${base05}";

        # bright
        color8 = "#${base03}";
        color9 = "#${base08}";
        color10 = "#${base0B}";
        color11 = "#${base0A}";
        color12 = "#${base0D}";
        color13 = "#${base0E}";
        color14 = "#${base0C}";
        color15 = "#${base07}";

        # extended base16 colors
        color16 = "#${base09}";
        color17 = "#${base0F}";
        color18 = "#${base01}";
        color19 = "#${base02}";
        color20 = "#${base04}";
        color21 = "#${base06}";
      };
    })
    (mkIf cfg.mako {
      # https://github.com/stacyharper/base16-mako
      services.mako = {
        backgroundColor = "#${base00}";
        textColor = "#${base05}";
        borderColor = "#${base0D}";

        extraConfig = ''
          [urgency=low]
          background-color=#${base00}
          text-color=#${base0A}
          border-color=#${base0D}

          [urgency=high]
          background-color=#${base00}
          text-color=#${base08}
          border-color=#${base0D}
        '';
      };
    })
    (mkIf cfg.qutebrowser {
      programs.qutebrowser.settings = {
        colors = {
          completion = {
            fg = "#${base05}";
            odd.bg = "#${base01}";
            even.bg = "#${base00}";
            category = {
              fg = "#${base0A}";
              bg = "#${base00}";
              border = {
                top = "#${base00}";
                bottom = "#${base00}";
              };
            };
            item = {
              selected = {
                fg = "#${base05}";
                bg = "#${base02}";
                border = {
                  top = "#${base02}";
                  bottom = "#${base02}";
                };
                match.fg = "#${base0B}";
              };
            };
            match.fg = "#${base0B}";
            scrollbar = {
              fg = "#${base05}";
              bg = "#${base00}";
            };
          };
          contextmenu = {
            disabled = {
              bg = "#${base01}";
              fg = "#${base04}";
            };
            menu = {
              bg = "#${base00}";
              fg = "#${base05}";
            };
            selected = {
              bg = "#${base02}";
              fg = "#${base05}";
            };
          };
          downloads = {
            bar.bg = "#${base00}";
            start = {
              fg = "#${base00}";
              bg = "#${base0D}";
            };
            stop = {
              fg = "#${base00}";
              bg = "#${base0C}";
            };
            error.fg = "#${base08}";
          };
          hints = {
            fg = "#${base00}";
            bg = "#${base0A}";
            match.fg = "#${base05}";
          };
          keyhint = {
            fg = "#${base05}";
            suffix.fg = "#${base05}";
            bg = "#${base00}";
          };
          messages = {
            error = {
              fg = "#${base00}";
              bg = "#${base08}";
              border = "#${base08}";
            };
            warning = {
              fg = "#${base00}";
              bg = "#${base0E}";
              border = "#${base0E}";
            };
            info = {
              fg = "#${base05}";
              bg = "#${base00}";
              border = "#${base00}";
            };
          };
          prompts = {
            fg = "#${base05}";
            border = "#${base00}";
            bg = "#${base00}";
            selected = {
              bg = "#${base02}";
              fg = "#${base05}";
            };
          };
          statusbar = {
            normal = {
              fg = "#${base0B}";
              bg = "#${base00}";
            };
            insert = {
              fg = "#${base00}";
              bg = "#${base0D}";
            };
            passthrough = {
              fg = "#${base00}";
              bg = "#${base0C}";
            };
            private = {
              fg = "#${base00}";
              bg = "#${base01}";
            };
            command = {
              fg = "#${base05}";
              bg = "#${base00}";
              private = {
                fg = "#${base05}";
                bg = "#${base00}";
              };
            };
            caret = {
              fg = "#${base00}";
              bg = "#${base0E}";
              selection = {
                fg = "#${base00}";
                bg = "#${base0D}";
              };
            };
            progress.bg = "#${base0D}";
            url = {
              fg = "#${base05}";
              error.fg = "#${base08}";
              hover.fg = "#${base05}";
              success.http.fg = "#${base0C}";
              success.https.fg = "#${base0B}";
              warn.fg = "#${base0E}";
            };
          };
          tabs = {
            bar.bg = "#${base00}";
            indicator = {
              start = "#${base0D}";
              stop = "#${base0C}";
              error = "#${base08}";
            };
            odd = {
              fg = "#${base05}";
              bg = "#${base01}";
            };
            even = {
              fg = "#${base05}";
              bg = "#${base00}";
            };
            pinned = {
              even = {
                bg = "#${base0C}";
                fg = "#${base07}";
              };
              odd = {
                bg = "#${base0B}";
                fg = "#${base07}";
              };
              selected = {
                even = {
                  bg = "#${base02}";
                  fg = "#${base05}";
                };
                odd = {
                  bg = "#${base02}";
                  fg = "#${base05}";
                };
              };
            };
            selected = {
              odd = {
                fg = "#${base05}";
                bg = "#${base02}";
              };
              even = {
                fg = "#${base05}";
                bg = "#${base02}";
              };
            };
          };
        };
      };
    })
    (mkIf cfg.wofi {
      # https://sr.ht/~knezi/base16-wofi/
      programs.wofi.style = ''
        window {
        	background-color: #${base00};
        	color: #${base05};
        }
        #entry:nth-child(odd) {
        	background-color: #${base00};
        }
        #entry:nth-child(even) {
        	background-color: #${base01};
        }
        #entry:selected {
        	background-color: #${base02};
        }
        #input {
        	background-color: #${base01};
        	color: #${base04};
        	border-color: #${base02};
        }
        #input:focus {
        	border-color: #${base0A};
        }
      '';
    })
  ]);
}
