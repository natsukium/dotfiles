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
      passwordCommand = "rbw get \"gmail app password for neomutt\"";
      notmuch.enable = true;
      neomutt = {
        enable = true;
        mailboxType = "imap";
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

  programs.neomutt = {
    enable = true;
    sidebar = {
      enable = true;
    };
    sort = "reverse-last-date-received";
    vimKeys = true;
    extraConfig = ''
      set pager_index_lines=10
    '';
  };

  my.programs.neomutt.enableHtmlView = true;
}
