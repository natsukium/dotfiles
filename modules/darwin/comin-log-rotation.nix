{
  config,
  lib,
  ...
}:
let
  cominLog = config.launchd.daemons.comin.serviceConfig.StandardOutPath;
in
{
  config = lib.mkIf config.services.comin.enable {
    my.services.newsyslog.settings.${cominLog} = {
      count = 10;
      size = 1000;
      flags = [ "Z" ];
    };

    # macOS newsyslog has no postcmd / arbitrary-command-after-rotate facility
    # (verified against the newsyslog(8) man page on Sonoma+); only signal
    # delivery to a PID file. Comin's launchd daemon does not write a PID file
    # and would not reopen its log file on SIGHUP anyway, so neither lever is
    # usable. We instead let launchd do the work: WatchPaths fires when the
    # watched path's inode or metadata changes, which is exactly what newsyslog
    # produces when it renames the rotated file and creates a fresh empty one.
    # The handler kickstarts comin so launchctl re-opens the fd against the
    # new file.
    launchd.daemons.comin-log-rotator = {
      serviceConfig = {
        Label = "com.dotfiles.comin-log-rotator";
        WatchPaths = [ cominLog ];
        # Brief sleep so newsyslog's create+chown finishes before kickstart
        ProgramArguments = [
          "/bin/sh"
          "-c"
          "/bin/sleep 1; exec /bin/launchctl kickstart -k system/com.github.nlewo.comin"
        ];
      };
    };
  };
}
