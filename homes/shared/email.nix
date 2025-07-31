{ config, pkgs, ... }:
let
  inherit (pkgs) lib stdenv;
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
      passwordCommand = "${lib.getExe' pkgs.coreutils "cat"} ${config.sops.secrets.gmail-app-password.path}";
      mbsync = {
        enable = true;
        create = "maildir";
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
      };
      notmuch.enable = true;
      neomutt.enable = true;
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

  programs.mbsync.enable = true;
  my.services.mbsync.enable = true;

  services.imapnotify.enable = true;

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

  sops.secrets.gmail-app-password = {
    sopsFile = ./secrets.yaml;
  };
}
