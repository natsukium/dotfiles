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
      package = inputs.felis.packages.${pkgs.stdenv.hostPlatform.system}.default;
      # The configured Neovim, reused as a read-only scrollback viewer.
      neovim = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.neovim;
      # My standalone hint picker; it links felis' own VT parser and cell
      # grid, so its label overlay lands on exactly the columns felis drew.
      spoor = inputs.spoor.packages.${pkgs.stdenv.hostPlatform.system}.default;

      # The pickers and hints live in a sibling file so this module
      # reads as configuration, not writeShellApplication bodies.
      inherit
        (import ./utilities.nix {
          inherit
            lib
            pkgs
            package
            neovim
            spoor
            ;
        })
        felis-switch
        felis-kill
        felis-grep
        felis-scrollback
        felis-hints
        felis-nix-log
        ;

      # Moralerspace ships each style as its own flavor, not weights of
      # one family, so each style names its flavor.
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
          felis-kill
          felis-grep
        ];

        programs.felis = {
          enable = true;
          inherit package;

          # Runs the module's relay (systemd user unit on Linux, launchd
          # agent on macOS) forwarding alerts to the platform notifier.
          notifications.enable = true;

          settings = {
            font = {
              family = moralerspace "Neon";
              size = 14.0;
              features = font-features;
              # Each flavor is a distinct family, so felis' bold/italic
              # derivation from the primary can't reach them; name them.
              bold.family = moralerspace "Xenon";
              italic.family = moralerspace "Radon";
              bold_italic.family = moralerspace "Krypton";
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
                # extended base16 colors
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
            window = {
              decorations = false;
            };

            keymap = {
              "¥" = {
                kind = "send_string";
                text = "\\";
                escapes = "none";
              };
              "shift+enter" = {
                kind = "send_string";
                text = "\\e\\r";
                escapes = "cstyle";
              };
              "ctrl+]" = {
                kind = "switch_next_session";
              };
              "ctrl+[" = {
                kind = "switch_previous_session";
              };
              "ctrl+shift+n" = {
                kind = "new_session";
              };
              # `run` launches the picker in a transient session over the
              # live grid; an absolute store path keeps it independent of
              # the daemon's minimal PATH.
              "ctrl+shift+p" = {
                kind = "run";
                command = [ "${felis-switch}/bin/felis-switch" ];
              };
              "ctrl+shift+d" = {
                kind = "run";
                command = [ "${felis-kill}/bin/felis-kill" ];
              };
              "ctrl+shift+g" = {
                kind = "run";
                command = [ "${felis-grep}/bin/felis-grep" ];
              };
              # The default +h binding keeps the pager; this routes the
              # same scrollback region into Neovim instead.
              "ctrl+shift+e" = {
                kind = "pipe";
                source = "scrollback";
                command = [ "${felis-scrollback}/bin/felis-scrollback" ];
              };
              # Hints over the visible grid. `ansi` defaults to false
              # (plain), which is exactly what spoor wants — embedded
              # SGR would corrupt the URL match.
              "ctrl+shift+o" = {
                kind = "pipe";
                source = "visible";
                command = [ "${felis-hints}/bin/felis-hints" ];
              };
              # The kitty Ctrl+Shift+l port: page the build log of a
              # `nix log <drv>` shown on screen.
              "ctrl+shift+l" = {
                kind = "pipe";
                source = "visible";
                command = [ "${felis-nix-log}/bin/felis-nix-log" ];
              };
            };
          };
        };
      };
    };
}
