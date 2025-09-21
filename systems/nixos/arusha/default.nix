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

  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liga-hackgen-nf-font
  ];

  environment.systemPackages = [ pkgs.coreutils ];
}
