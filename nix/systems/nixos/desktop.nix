{
  inputs,
  pkgs,
  ...
}: let
  nurpkgs =
    (import inputs.nur {
      inherit pkgs;
      nurpkgs = pkgs;
    })
    .repos
    .natsukium;
in {
  nixpkgs.overlays = [inputs.nur.overlay];
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    enableNvidiaPatches = true;
  };
  fonts.packages = with pkgs; [
    noto-fonts-cjk
    noto-fonts-emoji
    nurpkgs.liga-hackgen-nf-font
  ];

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };
}
