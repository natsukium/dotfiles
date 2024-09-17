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
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = ../../../secrets/default.yaml;
    age = {
      keyFile = "${impermanencePrefix}/var/lib/sops-nix/key.txt";
      sshKeyPaths = map (key: key.path) config.services.openssh.hostKeys;
      generateKey = true;
    };
  };

  system.stateVersion = "23.05";

  system.autoUpgrade = {
    enable = true;
    dates = "06:00";
    flake = "github:natsukium/dotfiles";
  };

  nixpkgs.config.allowUnfree = true;

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

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pinentryWrapper;
  };

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  services.prometheus = {
    enable = true;
    port = 9001;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };
    scrapeConfigs = [
      {
        job_name = config.networking.hostName;
        static_configs = [
          { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ]; }
        ];
      }
    ];
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
