{pkgs, ...}: {
  programs = {
    rbw = {
      enable = true;
      settings = {
        email = "tomoya.otabi@gmail.com";
        pinentry = "curses";
      };
    };
  };
}
