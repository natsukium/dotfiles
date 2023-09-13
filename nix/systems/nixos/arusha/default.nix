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
    ../../../modules/wsl/docker-enable-nvidia.nix
    ../../../modules/wsl/vscode.nix
    ../../../modules/nix
    ../common.nix
  ];

  programs.nix.target.nvidia = true;

  users.users.${username} = {
    home = "/home/${username}";
    isNormalUser = true;
    initialPassword = "";
    group = "wheel";
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

  environment.systemPackages = [pkgs.coreutils];

  vscode-wsl.enable = true;
}
