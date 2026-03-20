{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.mbsync;
  mbsyncExtraOptions =
    lib.optional (cfg.verbose) "--verbose"
    ++ lib.optional (cfg.configFile != null) "--config ${cfg.configFile}";

  mbsyncCmd = lib.concatStringsSep " " ([ (lib.getExe cfg.package) ] ++ mbsyncExtraOptions);

  # isync 1.5 drops the IMAP connection for the second account when
  # multiple XOAUTH2 accounts share the same server, causing
  # "read: unexpected EOF" with --all.  Running each channel in its
  # own process avoids the bug.
  # https://www.mail-archive.com/isync-devel@lists.sourceforge.net/msg04337.html
  mbsyncChannels = lib.attrNames (
    lib.filterAttrs (_: acc: acc.mbsync.enable) config.accounts.email.accounts
  );

  mbsyncAllScript = pkgs.writeShellScript "mbsync-all" (
    lib.concatMapStringsSep "\n" (channel: "${mbsyncCmd} ${lib.escapeShellArg channel}") mbsyncChannels
  );

  # launchd has no ExecStartPre/ExecStartPost equivalent,
  # so pre/post hooks are composed into a single wrapper script.
  syncScript = pkgs.writeShellScript "mbsync-sync" (
    lib.concatStringsSep "\n" (
      lib.optional (cfg.preExec != null) cfg.preExec
      ++ [ "${mbsyncAllScript}" ]
      ++ lib.optional (cfg.postExec != null) cfg.postExec
    )
  );
in
{
  options.my.services = { inherit (options.services) mbsync; };
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        services = { inherit (config.my.services) mbsync; };
      })

      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        launchd.agents.mbsync = {
          enable = true;
          config = {
            ProgramArguments = [ "${syncScript}" ];
            EnvironmentVariables = lib.optionalAttrs config.programs.notmuch.enable {
              NOTMUCH_CONFIG = "${config.xdg.configHome}/notmuch/default/config";
            };
            RunAtLoad = true;
            StartInterval = 300;
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/mbsync/stdout";
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/mbsync/stderr";
          };
        };
      })
    ]
  );
}
