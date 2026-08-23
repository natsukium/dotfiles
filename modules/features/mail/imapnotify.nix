{ ... }:
{
  flake.modules.homeManager.imapnotify =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        mkDefault
        mkIf
        mkOption
        optional
        types
        ;
      cfg = config.my.services.imapnotify;
      mbsync = config.my.services.mbsync;

      # Bound out here because the submodule below shadows `config` with the
      # account's own config.
      enabled = config.services.imapnotify.enable;

      # A pushed message stays invisible to notmuch until the indexing
      # pipeline has run, so push and the periodic job must share one
      # definition of it; postExec is where that definition already lives.
      indexAndNotify = lib.concatStringsSep "; " (
        optional (mbsync.postExec != null) mbsync.postExec
        ++ optional (cfg.notifyCommand != "") cfg.notifyCommand
      );
    in
    {
      options.my.services.imapnotify = {
        notifyCommand = mkOption {
          type = types.str;
          default =
            if pkgs.stdenv.hostPlatform.isLinux then
              "${lib.getExe pkgs.libnotify} 'New mail arrived'"
            else
              ''osascript -e "display notification \"New mail arrived\" with title \"email\""'';
          description = ''
            Shell command run after a pushed message has been indexed.
            Set to the empty string to only index, without notifying.
          '';
        };
      };

      # What to fetch and what to run afterwards is mechanical: every account
      # syncs the mbsync channel named after it, then runs the same indexing
      # pipeline. Deriving both here keeps adding an account down to declaring
      # its credentials, instead of repeating two commands per account per host
      # -- a repetition that had already drifted, leaving work mail unindexed
      # until the periodic job caught up.
      options.accounts.email.accounts = mkOption {
        type = types.attrsOf (
          types.submodule (
            { name, config, ... }:
            {
              config.imapnotify = mkIf (enabled && config.imapnotify.enable) {
                # mbsync names each channel after its account.
                onNotify = mkDefault "${lib.getExe mbsync.package} ${name}";
                onNotifyPost = mkDefault indexAndNotify;
              };
            }
          )
        );
      };
    };
}
