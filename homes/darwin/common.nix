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
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = {
      imports = [
        ../common.nix
      ];

      my.virtualisation.colima = {
        enable = true;
        settings = {
          cpu = 8;
          memory = 8;
        };
      };

      home.packages = with pkgs; [
        # without this, the older builtin `less` would be used
        less
      ];
    };
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
    };
  };
}
