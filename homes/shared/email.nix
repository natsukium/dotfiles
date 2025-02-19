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
}
