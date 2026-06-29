# This file is auto-generated from configuration.org.
# Do not edit directly.

{ ... }:
let
  # System scope: install fish, register it as a login shell, and make it the
  # primary user's default shell.
  systemModule =
    {
      config,
      lib,
      pkgs,
      username,
      ...
    }:
    {
      options.my.programs.fish.enable = lib.mkEnableOption "fish";

      config = lib.mkIf config.my.programs.fish.enable {
        programs.fish.enable = true;
        environment.shells = [ pkgs.fish ];
        users.users.${username}.shell = pkgs.fish;
      };
    };

  # Darwin layers macOS-only setup on top of the shared system config.
  darwinModule =
    {
      config,
      lib,
      username,
      ...
    }:
    {
      imports = [ systemModule ];

      config = lib.mkIf config.my.programs.fish.enable {
        # distributed builds fail with "fish: Unknown command: nix-store" over SSH;
        # source the nix-daemon vars so nix-store is reachable.
        # https://github.com/NixOS/nix/issues/7508#issuecomment-2597403478
        programs.fish.shellInit = ''
          if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish' && test -n "$SSH_CONNECTION"
            source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
          end
        '';

        # nix-darwin only manages a user's shell when the account is "known" and its
        # uid matches the existing one, so the shell setting above takes effect.
        # https://github.com/LnL7/nix-darwin/issues/1237#issuecomment-2562242340
        users.users.${username}.uid = lib.mkDefault 501;
        users.knownUsers = [ username ];
      };
    };
in
{
  flake.modules.nixos.fish = systemModule;
  flake.modules.darwin.fish = darwinModule;

  flake.modules.homeManager.fish =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.programs.fish.enable = lib.mkEnableOption "fish";

      config = lib.mkIf config.my.programs.fish.enable {
        programs.fish = {
          enable = true;

          interactiveShellInit = ''
            bind \cs zi

            # set done's variable
            set -U __done_min_cmd_duration 15000

            # set environment variable for pinentry
            if test "$SSH_CONNECTION" != ""
              set -x PINENTRY_USER_DATA "USE_CURSES"
            end

            # extra abbrs
            abbr -a L --position anywhere --set-cursor "% | less"
            abbr -a !! --position anywhere --function _abbr_last_history_item
            abbr -a extract_tar_gz --position command --regex ".+\.tar\.gz" --function _abbr_extract_tar_gz
            abbr -a dotdot --regex '^\.\.+$' --function _abbr_multicd

            ${pkgs.any-nix-shell}/bin/any-nix-shell fish | source
          '';

          shellAbbrs = {
            # spellchecker:off
            l = "ls";

            "--sxl" = {
              position = "anywhere";
              expansion =
                "--system x86_64-linux"
                + pkgs.lib.optionalString (
                  pkgs.stdenv.hostPlatform.isDarwin || pkgs.stdenv.hostPlatform.isAarch64
                ) " -j0";
            };
            "--sal" = {
              position = "anywhere";
              expansion =
                "--system aarch64-linux"
                + pkgs.lib.optionalString (
                  pkgs.stdenv.hostPlatform.isDarwin || pkgs.stdenv.hostPlatform.isx86_64
                ) " -j0";
            };
            "--sxd" = {
              position = "anywhere";
              expansion =
                "--system x86_64-darwin" + pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux " -j0";
            };
            "--sad" = {
              position = "anywhere";
              expansion =
                "--system aarch64-darwin" + pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux " -j0";
            };
            # spellchecker:on
          };

          functions = {
            _abbr_last_history_item = "echo $history[1]";
            _abbr_extract_tar_gz = "echo tar avfx $argv";
            _abbr_multicd = "echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)";
          };

          plugins = [
            {
              name = "done";
              src = pkgs.fishPlugins.done.src;
            }
            {
              name = "fzf-fish";
              src = pkgs.fishPlugins.fzf-fish.src;
            }
          ];
        };
      };
    };
}
