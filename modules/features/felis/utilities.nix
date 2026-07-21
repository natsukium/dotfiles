# This file is auto-generated from configuration.org.
# Do not edit directly.

{
  lib,
  pkgs,
  package,
  neovim,
  spoor,
}:
let
  # Wraps list/switch in an fzf picker: the built-in
  # switch_{next,previous}_session only steps in daemon order, so
  # jumping to a known session otherwise means retyping a 32-hex id.
  # The preview shows each session's live grid (capture --ansi), so
  # the choice is by content.
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

  # Cross-session scrollback grep; the built-in ctrl+shift+f facet
  # searches only the focused session. Dump every session's
  # scrollback, fuzzy-filter, then switch to the chosen line's
  # session. A session that refuses a capture is skipped, not fatal.
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

  # Target for the scrollback `pipe` keybind. felis writes the region
  # to a temp file and passes the path as the last argv slot (stdin is
  # the transient session's tty), so open it read-only in Neovim for
  # editor motions instead of a pager. `-R` plus noswapfile keeps it a
  # throwaway view; `G` lands at the newest line.
  felis-scrollback = pkgs.writeShellApplication {
    name = "felis-scrollback";
    runtimeInputs = [ neovim ];
    text = ''
      exec nvim -R \
        -c 'setlocal noswapfile' \
        -c 'normal! G' \
        "''${1:?no region file}"
    '';
  };

  # kitty-style URL hints for the plain-text URLs felis won't make
  # clickable (only OSC 8 links are). spoor reads the visible region
  # from the temp-file path in the last argv slot, keeping stdin free
  # for its /dev/tty overlay; `--action open` hands the pick to the
  # platform opener. Open-only: the transient pipe session sees only
  # its own FELIS_SESSION_ID, not the originating window's, so a pick
  # can't be routed back to the prompt.
  felis-hints = pkgs.writeShellApplication {
    name = "felis-hints";
    runtimeInputs = [
      spoor
    ]
    ++ lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.xdg-utils;
    text = ''
      exec spoor --preset url --action open "''${1:?no region file}"
    '';
  };

  # felis port of the kitty `nix log` hint: pick a `nix log <drv>` on
  # screen and page its build log. grep + fzf rather than a label
  # overlay because a hint picker can't disable its built-in path
  # matchers and the point is matching *only* the drv. A single
  # failed-build drv skips the picker entirely.
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
in
{
  inherit
    felis-switch
    felis-kill
    felis-grep
    felis-scrollback
    felis-hints
    felis-nix-log
    ;
}
