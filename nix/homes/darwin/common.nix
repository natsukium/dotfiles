{
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs) inputs username colorScheme;
in {
  imports = [
    inputs.home-manager.darwinModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = {
      imports = [
        ../common.nix
        ../../modules/nix
      ];
      programs.nix.target.user = true;
    };
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs colorScheme;
    };
  };
}
