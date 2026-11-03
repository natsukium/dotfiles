{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    inputs.nixos-wsl.nixosModules.wsl
    ../../../systems/nixos/common.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  my.profiles.base.enable = true;
  my.profiles.development.enable = true;

  my.home.enable = true;
  home-manager.users.${config.my.username} = {
    home.sessionVariablesExtra = ''
      export WIN_HOME=$(wslpath $(wslvar USERPROFILE))
    '';
  };

  wsl = {
    enable = true;
    defaultUser = "natsukium";
  };

  # WSL writes resolv.conf itself, so the tailnet nameservers set by the
  # tailscale feature would never take effect here.
  networking.nameservers = lib.mkForce [ ];
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
