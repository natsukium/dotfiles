{ config, pkgs, ... }:
let
  inherit (pkgs) lib;
in
{
  accounts.email.accounts = {
    gmail.primary = lib.mkForce false;
    work = {
      primary = true;
      address = "tomoya.otabi@attm.co.jp";
      flavor = "gmail.com";
      realName = "OTABI Tomoya";
      passwordCommand = "${lib.getExe config.my.services.pizauth.package} show work";
      mbsync = {
        enable = true;
        create = "maildir";
        extraConfig.account.AuthMechs = "XOAUTH2";
      };
      imapnotify = {
        enable = true;
        boxes = [ "Inbox" ];
        onNotify = "${lib.getExe config.my.services.mbsync.package} -a";
        onNotifyPost = ''osascript -e "display notification \"New mail arrived\" with title \"email\""'';
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

  my.services.pizauth.accounts.work = {
    authUri = "https://accounts.google.com/o/oauth2/auth";
    tokenUri = "https://oauth2.googleapis.com/token";
    clientIdSecret = "gmail-oauth-client-id-for-work";
    clientSecretSecret = "gmail-oauth-client-secret-for-work";
    scopes = [ "https://mail.google.com/" ];
    authUriFields.login_hint = "tomoya.otabi@attm.co.jp";
  };

  sops.secrets.gmail-oauth-client-id-for-work = {
    sopsFile = ./secrets.yaml;
  };
  sops.secrets.gmail-oauth-client-secret-for-work = {
    sopsFile = ./secrets.yaml;
  };
}
