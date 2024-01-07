{
  inputs,
  pkgs,
  specialArgs,
  ...
}:
let
  inherit (specialArgs) username;
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = {
      imports = [ ../../common.nix ];
    };
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
    };
  };
}
