{
  inputs,
  pkgs,
  config,
  ...
}:
{
  imports = [
    inputs.nixos-wsl.nixosModules.wsl
    ../../../modules/profiles/nixos/base.nix
    ../../../systems/nixos/common.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  my.home.enable = true;
  home-manager.users.${config.my.username} = {
    imports = [
      ../../../modules/profiles/home/base.nix
      ../../../modules/profiles/home/development.nix
    ];
    home.sessionVariablesExtra = ''
      export WIN_HOME=$(wslpath $(wslvar USERPROFILE))
    '';
  };

  wsl = {
    enable = true;
    defaultUser = "natsukium";
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  virtualisation.docker.enable = true;

  # nvidia-container-toolkit added an assertion requiring explicit driver
  # configuration. On WSL, drivers come from Windows.
  hardware.nvidia-container-toolkit = {
    enable = true;
    suppressNvidiaDriverAssertion = true;
  };

  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liga-hackgen-nf-font
  ];

  environment.systemPackages = [ pkgs.coreutils ];
}
