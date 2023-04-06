{
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs) inputs username;
  nurpkgs =
    (import inputs.nur {
      inherit pkgs;
    })
    .repos
    .natsukium;
in {
  imports = [
    inputs.nixos-wsl.nixosModules.wsl
    ../../modules/wsl/docker-enable-nvidia.nix
    ../../modules/wsl/vscode.nix
  ];

  system.stateVersion = "22.11";

  users.users.${username} = {
    home = "/home/${username}";
    isNormalUser = true;
    initialPassword = "";
    group = "wheel";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKPPimMzL7CcpSpmf1QisRFxdp1e/3C21GZsoyDgZvIu gazelle"
    ];
  };

  wsl = {
    enable = true;
    defaultUser = "gazelle";
    docker-native = {
      enable = true;
      enableNvidia = true;
    };
  };
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  fonts.fonts = with pkgs; [
    noto-fonts-cjk
    noto-fonts-emoji
    nurpkgs.liga-hackgen-nf-font
  ];
  i18n = {
    inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [fcitx5-mozc];
    };
    defaultLocale = "ja_JP.UTF-8";
    extraLocaleSettings = {
      LC_CTYPE = "en_US.UTF-8";
      LC_MESSAGES = "en_US.UTF-8";
    };
  };
  time.timeZone = "Asia/Tokyo";

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = [pkgs.coreutils];
  services.openssh = {
    enable = true;
    settings.passwordAuthentication = false;
  };
  programs.ssh.startAgent = true;
  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "curses";
  };
  vscode-wsl.enable = true;
}
