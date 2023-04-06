{
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs) inputs username colorScheme;
in {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = {
      imports = [../common.nix];
      home.packages = [pkgs.wslu];
      programs.bash.profileExtra = ''
        export WIN_HOME=$(wslpath $(wslvar USERPROFILE))
      '';
    };
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs colorScheme;
    };
  };
}
