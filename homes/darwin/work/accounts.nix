{ config, lib, ... }:
{
  accounts.email.accounts = {
    gmail.primary = lib.mkForce false;
    work = {
      primary = true;
      address = "tomoya.otabi@attm.co.jp";
      flavor = "gmail.com";
      realName = "OTABI Tomoya";
      passwordCommand = "cat ${config.sops.secrets.gmail-app-password-for-work.path}";
      mbsync.enable = true;
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

  sops.secrets.gmail-app-password-for-work = {
    sopsFile = ./secrets.yaml;
  };
}
