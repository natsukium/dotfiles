{ inputs, ... }:
let
  daemon =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.felis.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
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
      package = inputs.felis.packages.${pkgs.stdenv.hostPlatform.system}.default;
      # The configured Neovim, reused as a read-only scrollback viewer.
      neovim = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.neovim;
      # macOS doesn't surface Ctrl+Shift+<letter> reliably through winit,
      # which is why felis binds its own modal shortcuts to Cmd there
      # (keymap/default.rs apply_macos_additions). Follow that idiom so
      # these chords actually fire on both platforms.
      mod-shift = if pkgs.stdenv.hostPlatform.isDarwin then "cmd+shift" else "ctrl+shift";
      # felis emits no popups; relay its decoded notification stream to
      # whichever notifier the platform ships. terminal-notifier ignores
      # urgency, so only the Linux branch threads it through.
      notify =
        if pkgs.stdenv.hostPlatform.isDarwin then
          ''terminal-notifier -title "$title" -message "$body" >/dev/null 2>&1 || true''
        else
          ''
            urgency=$(printf '%s' "$line" | jq -r '.urgency // "normal"')
            notify-send -u "$urgency" -- "$title" "$body" || true'';
      font-features = [
        "calt"
        "liga"
        "ss01"
        "ss02"
        "ss03"
        "ss05"
        "ss09"
      ];
      # The built-in keymap only walks sessions in daemon order
      # (switch_{next,previous}_session); jumping straight to a known
      # session means eyeballing `felis sessions list` and retyping a
      # 32-hex id. This wraps list/switch in an fzf picker instead, bound
      # to a key via the `run` action below. The preview pane shows each
      # session's live grid via `sessions capture --ansi` (colour
      # reconstructed), so the choice is by content, not opaque id.
      felis-switch = pkgs.writeShellApplication {
        name = "felis-switch";
        runtimeInputs = [
          package
          pkgs.fzf
          pkgs.gawk
        ];
        text = ''
          list=$(felis sessions list)
          if [ -z "$list" ] || [ "$list" = "no sessions" ]; then
            echo "no sessions" >&2
            exit 0
          fi

          # Drop this window's own session: switching to where you
          # already are is a no-op, so it only clutters the list.
          selection=$(
            printf '%s\n' "$list" \
              | awk -v self="''${FELIS_SESSION_ID:-}" '$1 != self' \
              | fzf --ansi \
                    --with-nth=2.. \
                    --prompt='felis session> ' \
                    --preview='felis sessions capture {1} --ansi 2>/dev/null || echo "(attached — preview unavailable)"'
          ) || exit 0

          id=''${selection%% *}
          [ -n "$id" ] && felis sessions switch "$id"
        '';
      };

      # Multi-select cousin of felis-switch for tearing sessions down.
      # The same `capture --ansi` preview identifies a parked session by
      # its screen before it is killed.
      felis-kill = pkgs.writeShellApplication {
        name = "felis-kill";
        runtimeInputs = [
          package
          pkgs.fzf
          pkgs.gawk
        ];
        text = ''
          list=$(felis sessions list)
          if [ -z "$list" ] || [ "$list" = "no sessions" ]; then
            echo "no sessions" >&2
            exit 0
          fi

          selection=$(
            printf '%s\n' "$list" \
              | fzf --ansi \
                    --multi \
                    --with-nth=2.. \
                    --prompt='kill session(s)> ' \
                    --preview='felis sessions capture {1} --ansi 2>/dev/null || echo "(attached — preview unavailable)"'
          ) || exit 0

          printf '%s\n' "$selection" \
            | awk 'NF {print $1}' \
            | while read -r id; do
                felis sessions kill "$id"
              done
        '';
      };

      # Cross-session scrollback grep. The built-in ctrl+shift+f facet
      # searches only the focused session, so dump every session's
      # retained scrollback, fuzzy-filter the lot, then switch to the
      # session the chosen line belongs to. A session that refuses a
      # capture (e.g. a transient one) is skipped, not fatal.
      felis-grep = pkgs.writeShellApplication {
        name = "felis-grep";
        runtimeInputs = [
          package
          pkgs.fzf
          pkgs.gawk
        ];
        text = ''
          matches=$(
            felis sessions list \
              | awk 'NF {print $1}' \
              | while read -r id; do
                  felis sessions capture "$id" --scrollback 2>/dev/null \
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

      # Target for the scrollback `pipe` keybind: felis streams the
      # retained scrollback to stdin; open it read-only in Neovim so it
      # can be searched and yanked with full editor motions rather than a
      # pager. nofile/wipe keeps it a throwaway buffer; `G` lands at the
      # newest line.
      felis-scrollback = pkgs.writeShellApplication {
        name = "felis-scrollback";
        runtimeInputs = [ neovim ];
        text = ''
          exec nvim -R \
            -c 'setlocal buftype=nofile bufhidden=wipe noswapfile' \
            -c 'normal! G' \
            -
        '';
      };

      # kitty-style URL hints for the plain-text URLs felis won't make
      # clickable (only OSC 8 links are). The `pipe` action serializes
      # the visible grid plain and soft-wrap-stitched, so thumbs sees
      # whole URLs; thumbs overlays single-key labels and prints the
      # pick, which we open. Open is the only action wired: routing a
      # pick back into the prompt is impossible today because the
      # transient pipe session only sees its own FELIS_SESSION_ID, not
      # the originating window's.
      felis-hints = pkgs.writeShellApplication {
        name = "felis-hints";
        runtimeInputs = [
          pkgs.thumbs
        ] ++ lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.xdg-utils;
        text = ''
          # felis passes the region as a temp-file path in the last argv
          # slot; thumbs reads the screen from stdin and draws its hint
          # overlay on /dev/tty, so feed the file in and act on the pick.
          sel=$(thumbs -u -r < "''${1:?no region file}") || exit 0
          [ -n "$sel" ] || exit 0
          ${if pkgs.stdenv.hostPlatform.isDarwin then "open" else "xdg-open"} "$sel"
        '';
      };

      # The felis port of the kitty `nix log` hint (was Ctrl+Shift+l):
      # pick a `nix log <drv>` printed on screen and page its build log.
      # grep + fzf rather than thumbs because thumbs cannot disable its
      # built-in URL/path matchers, so a thumbs overlay would light up
      # every path too; kitty's value here is matching *only* the drv.
      # The common case is a single failed-build drv, which skips the
      # picker entirely — faster than kitty, which always wants a label.
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

      # Relay felis's JSON-lines notification stream to the platform
      # notifier. Run as a user service (below) so background sessions
      # still surface alerts.
      felis-notify = pkgs.writeShellApplication {
        name = "felis-notify";
        runtimeInputs =
          [
            package
            pkgs.jq
          ]
          ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin pkgs.terminal-notifier
          ++ lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.libnotify;
        text = ''
          felis notifications subscribe | while IFS= read -r line; do
            if [ -z "$line" ]; then continue; fi
            title=$(printf '%s' "$line" | jq -r '.title // .session_title // "felis"')
            body=$(printf '%s' "$line" | jq -r '.body // ""')
            ${notify}
          done
        '';
      };
    in
    {
      imports = [ inputs.felis.homeManagerModules.felis ];

      options.my.programs.felis.enable = lib.mkEnableOption "felis";

      config = lib.mkIf config.my.programs.felis.enable (
        lib.mkMerge [
          {
        home.packages = [
          felis-switch
          felis-kill
          felis-grep
        ];

        programs.felis = {
          enable = true;
          inherit package;

          settings = {
            font = {
              family = "Moralerspace Neon HW";
              size = 14.0;
              features = font-features;
            };

            theme = {
              fg = "#${palette.base05}";
              bg = "#${palette.base00}";
              cursor = "#${palette.base05}";
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
              };
            };
            window = {
              opacity = 0.9;
              blur = true;
            };

            keymap = {
              "ctrl+]" = {
                kind = "switch_next_session";
              };
              "ctrl+[" = {
                kind = "switch_previous_session";
              };
              "${mod-shift}+n" = {
                kind = "new_session";
              };
              # `run` launches the picker in a transient session over the
              # live grid; an absolute store path keeps it independent of
              # the daemon's minimal PATH.
              "${mod-shift}+p" = {
                kind = "run";
                command = [ "${felis-switch}/bin/felis-switch" ];
              };
              "${mod-shift}+d" = {
                kind = "run";
                command = [ "${felis-kill}/bin/felis-kill" ];
              };
              "${mod-shift}+g" = {
                kind = "run";
                command = [ "${felis-grep}/bin/felis-grep" ];
              };
              # The default +h binding keeps the pager; this routes the
              # same scrollback region into Neovim instead.
              "${mod-shift}+e" = {
                kind = "pipe";
                source = "scrollback";
                command = [ "${felis-scrollback}/bin/felis-scrollback" ];
              };
              # Hints over the visible grid. `ansi` defaults to false
              # (plain), which is exactly what thumbs wants — embedded
              # SGR would corrupt the URL match.
              "${mod-shift}+o" = {
                kind = "pipe";
                source = "visible";
                command = [ "${felis-hints}/bin/felis-hints" ];
              };
              # The kitty Ctrl+Shift+l port: page the build log of a
              # `nix log <drv>` shown on screen.
              "${mod-shift}+l" = {
                kind = "pipe";
                source = "visible";
                command = [ "${felis-nix-log}/bin/felis-nix-log" ];
              };
            };
          };
        };
          }

          # mkMerge + mkIf rather than `// optionalAttrs`: the daemon
          # ships on both platforms, and making the *presence* of these
          # keys depend on `pkgs` would feed the module evaluator a
          # pkgs→config→pkgs cycle. mkIf defers the condition past key
          # resolution.
          (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
            launchd.agents.felis-notify = {
              enable = true;
              config = {
                ProgramArguments = [ "${felis-notify}/bin/felis-notify" ];
                KeepAlive = true;
                RunAtLoad = true;
                # No daemon yet at login means subscribe exits; back off
                # instead of respawning in a tight loop.
                ThrottleInterval = 10;
              };
            };
          })

          (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
            systemd.user.services.felis-notify = {
              Unit = {
                Description = "Relay felis desktop notifications to notify-send";
                PartOf = [ "graphical-session.target" ];
              };
              Service = {
                ExecStart = "${felis-notify}/bin/felis-notify";
                Restart = "always";
                RestartSec = 10;
              };
              Install.WantedBy = [ "graphical-session.target" ];
            };
          })
        ]
      );
    };
}
