{ config, pkgs, ... }:
let
  inherit (pkgs) lib stdenv;
  isyncWithCyrusSaslXoauth2 = pkgs.isync.override { withCyrusSaslXoauth2 = true; };

  # isync 1.5 drops the IMAP connection for the second account when
  # multiple XOAUTH2 accounts share the same server, causing
  # "read: unexpected EOF" with --all.  Running each channel in its
  # own process avoids the bug.
  # https://www.mail-archive.com/isync-devel@lists.sourceforge.net/msg04337.html
  mbsyncChannels = lib.attrNames (
    lib.filterAttrs (_: acc: acc.mbsync.enable) config.accounts.email.accounts
  );
  mbsyncCmd = lib.getExe config.my.services.mbsync.package;
  mbsyncAllScript = pkgs.writeShellScript "mbsync-all" (
    lib.concatMapStringsSep "\n" (channel: "${mbsyncCmd} ${lib.escapeShellArg channel}") mbsyncChannels
  );

  notmuchCmd = lib.getExe pkgs.notmuch;
  notmuchAccounts = lib.attrNames (
    lib.filterAttrs (_: acc: acc.notmuch.enable) config.accounts.email.accounts
  );
  # notmuch alone only manages tags; it does not move files between
  # maildir folders, so an explicit move is needed before sync.
  # Running in postNew (not preNew) so that notmuch has already
  # re-indexed the maildir and file paths in the database are fresh.
  # In preNew the database still holds paths from the previous run,
  # which become stale when mbsync renames files for flag changes.
  moveDeletedToTrash = pkgs.writeShellScript "notmuch-move-deleted-to-trash" ''
    db_path=$(${notmuchCmd} config get database.path)
    ${lib.concatMapStrings (name: ''
      mkdir -p "$db_path/${name}/[Gmail]/Trash/cur"
    '') notmuchAccounts}
    ${notmuchCmd} search --output=files tag:deleted -- ${
      lib.concatMapStringsSep " " (name: "not 'folder:${name}/[Gmail]/Trash'") notmuchAccounts
    } | while IFS= read -r file; do
      case "$file" in
      ${lib.concatMapStrings (name: ''
        "$db_path"/${name}/*) mv -- "$file" "$db_path/${name}/[Gmail]/Trash/cur/" ;;
      '') notmuchAccounts}
      esac
    done
  '';
in
{
  accounts.email = {
    maildirBasePath = "Mail";
  };

  accounts.email.accounts = {
    gmail = {
      primary = true;
      address = "tomoya.otabi@gmail.com";
      flavor = "gmail.com";
      realName = "OTABI Tomoya";
      passwordCommand = "${lib.getExe config.my.services.pizauth.package} show gmail";
      mbsync = {
        enable = true;
        create = "maildir";
        # without this, mbsync errors on mailboxes that were deleted or
        # renamed on the remote side (e.g. after changing Gmail's display
        # language) because it still tracks them in local state files
        remove = "maildir";
        expunge = "both";
        extraConfig.account.AuthMechs = "XOAUTH2";
      };
      imapnotify = {
        enable = true;
        boxes = [ "Inbox" ];
        onNotify = "${lib.getExe config.my.services.mbsync.package} gmail";
        onNotifyPost =
          if stdenv.hostPlatform.isLinux then
            "${lib.getExe pkgs.libnotify} 'New mail arrived'"
          else
            ''osascript -e "display notification \"New mail arrived\" with title \"email\""'';
        extraConfig.xoAuth2 = true;
      };
      notmuch.enable = true;
      neomutt = {
        enable = true;
        extraConfig = ''
          set smtp_authenticators = "xoauth2"
        '';
      };
      # to sync with GMail's trash, I need to add the label like "+[Gmail]/ゴミ箱"
      # but labels with Japanese characters are not supported by neomutt
      # so I set the display language to English(US) in GMail settings
      folders = {
        inbox = "Inbox";
        sent = "\[Gmail\]/Sent\\ Mail";
        trash = "\[Gmail\]/Trash";
        drafts = "\[Gmail\]/Drafts";
      };
    };
  };

  programs.mbsync = {
    enable = true;
    package = isyncWithCyrusSaslXoauth2;
  };
  my.services.mbsync = {
    enable = true;
    package = isyncWithCyrusSaslXoauth2;
  };

  services.imapnotify.enable = true;

  programs.notmuch = {
    enable = true;
    hooks.preNew = ''
      ${mbsyncAllScript}
    '';
    hooks.postNew = ''
      ${moveDeletedToTrash}
    '';
  };

  programs.neomutt = {
    enable = true;
    sidebar = {
      enable = true;
    };
    sort = "reverse-last-date-received";
    vimKeys = true;
    settings = {
      # Display format for email timestamps:
      # - Today's emails: time only
      # - This year's emails: month/day/weekday/time
      # - Previous years: year/month/day/time
      # https://neomutt.org/feature/cond-date
      index_format = "'%4C %Z %<[y?%<[d?%[           %R]&%[%m/%d (%a) %R]>&%[%Y/%m/%d %R]> %-15.15L (%?l?%4l&%4c?) %s'";
    };
    extraConfig = ''
      set pager_index_lines=10
    '';
  };

  my.programs.neomutt.enableHtmlView = true;

  my.services.pizauth = {
    enable = true;
    # On macOS, unset XDG_RUNTIME_DIR so pizauth falls back to
    # $TMPDIR/runtime-$USER, which is consistent between launchd and
    # interactive shells (launchd can't expand shell variables in
    # EnvironmentVariables, making XDG_RUNTIME_DIR unreliable).
    package =
      if pkgs.stdenv.hostPlatform.isDarwin then
        pkgs.writeShellApplication {
          name = "pizauth";
          text = ''
            unset XDG_RUNTIME_DIR
            ${lib.getExe pkgs.pizauth} "$@"
          '';
        }
      else
        pkgs.pizauth;
    accounts.gmail = {
      authUri = "https://accounts.google.com/o/oauth2/auth";
      tokenUri = "https://oauth2.googleapis.com/token";
      clientIdSecret = "gmail-oauth-client-id";
      clientSecretSecret = "gmail-oauth-client-secret";
      scopes = [ "https://mail.google.com/" ];
      authUriFields.login_hint = "tomoya.otabi@gmail.com";
    };
  };

  sops.secrets.gmail-oauth-client-id = {
    sopsFile = ./secrets.yaml;
  };
  sops.secrets.gmail-oauth-client-secret = {
    sopsFile = ./secrets.yaml;
  };
}
