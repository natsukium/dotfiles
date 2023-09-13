{username, ...}: {
  imports = [
    ../common.nix
  ];

  system.stateVersion = "23.05";

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Asia/Tokyo";

  i18n = {
    defaultLocale = "ja_JP.UTF-8";
    extraLocaleSettings = {
      LC_COLLATE = "C.UTF-8";
      LC_MESSAGES = "en_US.UTF-8";
    };
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  programs.ssh.startAgent = true;

  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "curses";
  };

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  users.users.${username} = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKPPimMzL7CcpSpmf1QisRFxdp1e/3C21GZsoyDgZvIu gazelle"
    ];
  };
}
