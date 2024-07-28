{ inputs, pkgs, ... }:
{
  imports = [
    inputs.nixos-wsl.nixosModules.wsl
    ../../../modules/wsl/vscode.nix
    ../../../modules/nix
    ../common.nix
  ];

  programs.nix.target.nvidia = true;

  wsl = {
    enable = true;
    defaultUser = "natsukium";
    nativeSystemd = true;
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
    noto-fonts-cjk
    noto-fonts-emoji
    liga-hackgen-nf-font
  ];

  environment.systemPackages = [ pkgs.coreutils ];

  vscode-wsl.enable = true;
}
