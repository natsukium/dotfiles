{ config, pkgs, ... }:
let
  inherit (pkgs) lib stdenv;
  isyncWithCyrusSaslXoauth2 = pkgs.isync.override { withCyrusSaslXoauth2 = true; };
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
      passwordCommand = "${lib.getExe pkgs.pizauth} show gmail";
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
        onNotify = "${lib.getExe config.my.services.mbsync.package} -a";
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
    hooks.preNew = "${lib.getExe config.my.services.mbsync.package} -a";
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
