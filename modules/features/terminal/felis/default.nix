# This file is auto-generated from configuration.org.
# Do not edit directly.

{ inputs, ... }:
let
  daemon =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.programs.felis.enable = lib.mkEnableOption "felis";

      config = lib.mkIf config.my.programs.felis.enable {
        environment.systemPackages = [
          inputs.felis.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
      };
    };
in
{
  flake.modules.nixos.felis = daemon;
  flake.modules.darwin.felis = daemon;

  flake.modules.homeManager.felis =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.colorScheme) palette;
      inherit (config.lib) appIdentity;
      package =
        let
          felis = inputs.felis.packages.${pkgs.stdenv.hostPlatform.system}.default;
        in
        if pkgs.stdenv.hostPlatform.isDarwin then appIdentity.stabilizeApp felis else felis;
      neovim = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.neovim;
      pouncer = inputs.pouncer.packages.${pkgs.stdenv.hostPlatform.system}.default;

      opener = if pkgs.stdenv.hostPlatform.isDarwin then "open" else "xdg-open";

      # `--format json` is the only stable shape felis promises. Columns are
      # space-padded in jq because fzf applies a single uniform `--tabstop`.
      roster = ''
        roster() {
          felis sessions list --format json \
            | jq -r --arg mode "''${1:-all}" '
                .sessions[]
                | select(.exited != true)
                | ([.program_status[]?.state]) as $states
                | (["blocked", "error", "working", "done", "idle"]
                   | map(select(. as $s | $states | index($s)))
                   | first // "-") as $status
                | select($mode != "waiting"
                         or ($status | IN("blocked", "error", "done")))
                | [
                    .id,
                    ((.short_id + "         ")[:9]
                     + ($status + "         ")[:9]
                     + (((.cwd // "" | sub("^file://[^/]*"; ""))
                         | if . == "" then "-"
                           else sub("^/(Users|home)/[^/]+"; "~")
                             | split("/")
                             | last
                           end)
                        + "               ")[:15]
                     + ((.foreground // "-") + "                ")[:16]
                     + (.title // ""))
                  ]
                | @tsv'
        }
      '';

      felis-switch = pkgs.writeShellApplication {
        name = "felis-switch";
        runtimeInputs = [
          package
          pkgs.fzf
          pkgs.jq
        ];
        text = ''
          # A `run` action runs in its own transient session (FELIS_SESSION_ID), while
          # FELIS_ORIGIN_SESSION_ID is the session the window came from; exclude both.
          ${roster}
          candidates() {
            roster "$1" | grep -v -e "''${FELIS_ORIGIN_SESSION_ID:-none}" -e "''${FELIS_SESSION_ID:-none}" || true
          }

          if [ "''${1:-}" = --list ]; then
            candidates "''${2:-all}"
            exit 0
          fi

          list=$(candidates all)
          if [ -z "$list" ]; then
            echo "no sessions" >&2
            exit 0
          fi

          self=$(printf %q "$0")
          # fzf runs bind commands through $SHELL (fish), so pin bash with --with-shell.
          selection=$(
            printf '%s\n' "$list" \
              | fzf --ansi \
                    --multi \
                    --delimiter='\t' \
                    --with-nth=2.. \
                    --with-shell="${pkgs.runtimeShell} -c" \
                    --prompt='all> ' \
                    --header='enter: switch / ctrl-x: kill / alt-w: toggle waiting' \
                    --preview='felis sessions capture {1} --ansi' \
                    --preview-window='right,50%,<80(up,50%)' \
                    --bind="ctrl-x:execute-silent(for id in {+1}; do felis sessions kill \"\$id\"; done)+reload($self --list \"\''${FZF_PROMPT%> }\")" \
                    --bind="alt-w:transform:if [ \"\$FZF_PROMPT\" = 'waiting> ' ]; then echo 'change-prompt(all> )+reload($self --list all)'; else echo 'change-prompt(waiting> )+reload($self --list waiting)'; fi"
          ) || exit 0

          id=''${selection%%$'\t'*}
          [ -n "$id" ] && felis sessions switch "$id"
        '';
      };

      felis-grep = pkgs.writeShellApplication {
        name = "felis-grep";
        runtimeInputs = [
          package
          pkgs.fzf
          pkgs.gawk
          pkgs.jq
        ];
        text = ''
          ${roster}
          matches=$(
            roster \
              | awk -F'\t' 'NF {print $1}' \
              | while read -r id; do
                  felis sessions capture "$id" --source scrollback 2>/dev/null \
                    | awk -v id="$id" 'NF {print id"\t"$0}'
                done
          )
          if [ -z "$matches" ]; then
            echo "no scrollback" >&2
            exit 0
          fi

          selection=$(
            printf '%s\n' "$matches" \
              | fzf --delimiter='\t' --with-nth=2.. --prompt='grep scrollback> '
          ) || exit 0

          id=$(printf '%s' "$selection" | awk -F'\t' '{print $1; exit}')
          [ -n "$id" ] && felis sessions switch "$id"
        '';
      };

      # Expand `~` in the shell rather than using pouncer's `--action open`, which
      # passes `~` literally to the opener.
      felis-hints = pkgs.writeShellApplication {
        name = "felis-hints";
        runtimeInputs = [
          pouncer
        ]
        ++ lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.xdg-utils;
        text = ''
          picked=$(pouncer \
            --preset url \
            --regex '[\w.~/@+-]+\.(?i:html?|pdf|md|markdown)\b' \
            "''${1:?no region file}") || exit 0
          [ -n "$picked" ] || exit 0
          # shellcheck disable=SC2088
          case $picked in
            "~/"*) picked=$HOME/''${picked#"~/"} ;;
          esac
          case ''${picked,,} in
            *.md | *.markdown)
              exec ${config.programs.emacs.finalPackage}/bin/emacsclient -c -n "$picked" ;;
          esac
          exec ${opener} "$picked"
        '';
      };

      felis-nix-log = pkgs.writeShellApplication {
        name = "felis-nix-log";
        runtimeInputs = [
          pkgs.nix
          pkgs.fzf
          pkgs.gnused
          pkgs.gawk
          pkgs.less
        ];
        text = ''
          mapfile -t drvs < <(
            grep -oE 'nix log /nix/store/[a-z0-9]{32}-[^ ]+\.drv' "''${1:?no region file}" \
              | sed 's/^nix log //' \
              | awk '!seen[$0]++'
          )
          case ''${#drvs[@]} in
            0) echo "no 'nix log <drv>' on screen" >&2; exit 0 ;;
            1) drv=''${drvs[0]} ;;
            *) drv=$(printf '%s\n' "''${drvs[@]}" | fzf --prompt='nix log> ') || exit 0 ;;
          esac
          [ -n "$drv" ] && nix log "$drv" | less -R
        '';
      };

      moralerspace = flavor: "Moralerspace ${flavor} HW";
      font-features = [
        "calt"
        "liga"
        "ss01"
        "ss02"
        "ss03"
        "ss05"
        "ss09"
      ];
    in
    {
      imports = [ inputs.felis.homeManagerModules.felis ];

      options.my.programs.felis.enable = lib.mkEnableOption "felis";

      config = lib.mkIf config.my.programs.felis.enable {
        my.programs.coding-agents.skills.felis = "${inputs.felis}/skills/felis";

        home.packages = [
          felis-switch
          felis-grep
        ];

        programs.felis = {
          enable = true;
          inherit package;
          notifications.enable = true;

          settings = {
            font = {
              family = moralerspace "Neon";
              size_px = 14.0;
              features = font-features;
              bold.family = moralerspace "Xenon";
              italic.family = moralerspace "Radon";
              bold_italic.family = moralerspace "Krypton";
            };

            theme = {
              foreground = "#${palette.base05}";
              background = "#${palette.base00}";
              palette = {
                black = "#${palette.base00}";
                red = "#${palette.base08}";
                green = "#${palette.base0B}";
                yellow = "#${palette.base0A}";
                blue = "#${palette.base0D}";
                magenta = "#${palette.base0E}";
                cyan = "#${palette.base0C}";
                white = "#${palette.base05}";
                bright_black = "#${palette.base03}";
                bright_red = "#${palette.base08}";
                bright_green = "#${palette.base0B}";
                bright_yellow = "#${palette.base0A}";
                bright_blue = "#${palette.base0D}";
                bright_magenta = "#${palette.base0E}";
                bright_cyan = "#${palette.base0C}";
                bright_white = "#${palette.base07}";
                indexed = {
                  "16" = "#${palette.base09}";
                  "17" = "#${palette.base0F}";
                  "18" = "#${palette.base01}";
                  "19" = "#${palette.base02}";
                  "20" = "#${palette.base04}";
                  "21" = "#${palette.base06}";
                };
              };
            };
            cursor.color = "#${palette.base05}";

            window = {
              decorations = false;
              macos_option_as_alt = true;
            };

            keymap = {
              "¥" = {
                kind = "send_string";
                text = "\\";
                escapes = "none";
              };
              "ctrl+]" = {
                kind = "switch_session";
                to = "next";
              };
              "ctrl+[" = {
                kind = "switch_session";
                to = "previous";
              };
              "ctrl+shift+n" = {
                kind = "new_session";
              };
              "ctrl+shift+p" = {
                kind = "run";
                command = [ "${felis-switch}/bin/felis-switch" ];
              };
              "ctrl+shift+g" = {
                kind = "run";
                command = [ "${felis-grep}/bin/felis-grep" ];
              };
              # Pipe actions pass the captured region's temp-file path as the last argument.
              "ctrl+shift+e" = {
                kind = "pipe";
                source = "scrollback";
                target.command = [
                  "${neovim}/bin/nvim"
                  "-R"
                  "-c"
                  "setlocal noswapfile"
                  "-c"
                  "normal! G"
                ];
              };
              # pouncer parses ANSI through felis' VT engine and matches on cells,
              # so ansi = true only colours the repaint.
              "ctrl+shift+o" = {
                kind = "pipe";
                source = "visible";
                ansi = true;
                target.command = [ "${felis-hints}/bin/felis-hints" ];
              };
              "ctrl+shift+l" = {
                kind = "pipe";
                source = "visible";
                target.command = [ "${felis-nix-log}/bin/felis-nix-log" ];
              };
            };

            mouse.scroll_multiplier = 5.0;
          };
        };
      };
    };
}
