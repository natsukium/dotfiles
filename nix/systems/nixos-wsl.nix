{
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs) inputs;
  nurpkgs =
    (import inputs.nur {
      inherit pkgs;
    })
    .repos
    .natsukium;
in {
  imports = [../modules/wsl/docker-enable-nvidia.nix ../modules/wsl/vscode.nix];

  system.stateVersion = "22.11";

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
      enabled = "fcitx";
      fcitx.engines = with pkgs.fcitx-engines; [mozc];
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
