{ inputs, pkgs, ... }:
{
  imports = [
    inputs.nixos-wsl.nixosModules.wsl
    ../../../modules/profiles/nixos/base.nix
    ../common.nix
  ];

  wsl = {
    enable = true;
    defaultUser = "natsukium";
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
  };

  # docker.enableNvidia enables nvidia-container-toolkit, which added an assertion
  # requiring explicit driver configuration. On WSL, drivers come from Windows.
  hardware.nvidia-container-toolkit.suppressNvidiaDriverAssertion = true;

  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liga-hackgen-nf-font
  ];

  environment.systemPackages = [ pkgs.coreutils ];
}
