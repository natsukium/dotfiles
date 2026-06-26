{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixos-wsl.nixosModules.wsl
    ../../../modules/profiles/nixos/base.nix
    ../../../systems/nixos/common.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

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

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = builtins.attrValues inputs.self.modules.homeManager;
    users.${config.my.username} = {
      imports = [
        ../../../homes/common.nix
        ../../../modules/profiles/home/base.nix
        ../../../modules/profiles/home/development.nix
      ];
      home.sessionVariablesExtra = ''
        export WIN_HOME=$(wslpath $(wslvar USERPROFILE))
      '';
    };
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
    };
  };
}
