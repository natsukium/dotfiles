{
  config,
  username,
  inputs,
  pkgs,
  ...
}:
let
  # put the ssh auth key in the persist directory or it cannot be accessed at boot time
  # https://github.com/Mic92/sops-nix/blob/99b1e37f9fc0960d064a7862eb7adfb92e64fa10/README.md?plain=1#L594-L596
  hasImpermanence = config.environment ? "persistence";
  impermanencePrefix = pkgs.lib.optionalString hasImpermanence "/persistent";
  pinentryWrapper = pkgs.callPackage ../../pkgs/pinentry-wrapper { };
in
{
  imports = [
    ../../modules/nixos
    ../common.nix
    ./services/tailscale
    inputs.comin.nixosModules.comin
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    inputs.tsnsrv.nixosModules.default
  ];

  sops = {
    defaultSopsFile = ../../secrets/default.yaml;
    age = {
      keyFile = "${impermanencePrefix}/var/lib/sops-nix/key.txt";
      sshKeyPaths = map (key: key.path) config.services.openssh.hostKeys;
      generateKey = true;
    };
  };

  system.stateVersion = "24.11";

  time.timeZone = "Asia/Tokyo";

  i18n = {
    # Using tailscale SSH to access remote store fails to load extra locales
    # /nix/store/fx3g0sgldmgh8dpcw8j8ynx99nry1mf2-set-environment: line 12: warning: setlocale: LC_MESSAGES: cannot change locale (en_US.UTF-8): No such file or directory
    # related issues
    # https://discourse.nixos.org/t/tailscale-ssh-destroys-nix-copy/38781
    # https://github.com/tailscale/tailscale/issues/4940
    defaultLocale = "en_US.UTF-8";
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    hostKeys = [
      {
        path = "${impermanencePrefix}/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  programs.ssh.startAgent = true;
  services.gnome.gcr-ssh-agent.enable = false;

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pinentryWrapper;
  };

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
    # fix DNS issue caused by systemd-resolved
    # https://discourse.nixos.org/t/rootless-docker-systemd-resolved-and-dns-inside-containers/47030
    daemon.settings = {
      dns = [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };
  };

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
  };

  users = {
    mutableUsers = false;
  };

  users.users.${username} = {
    home = "/home/${username}";
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.login-password.path;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKPPimMzL7CcpSpmf1QisRFxdp1e/3C21GZsoyDgZvIu tomoya.otabi@gmail.com"
    ];
  };

  sops.secrets.login-password.neededForUsers = true;
}
