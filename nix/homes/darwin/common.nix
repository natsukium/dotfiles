{
  inputs,
  config,
  pkgs,
  specialArgs,
  ...
}:
let
  inherit (specialArgs) username;
  nurpkgs = config.nur.repos.natsukium;
in
{
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = {
      imports = [
        ../common.nix
        ../../modules/nix
      ];

      programs.colima = {
        enable = true;
        package = nurpkgs.colima;
        settings = {
          cpu = 8;
          memory = 8;
        };
      };

      home.packages = with pkgs; [
        # without this, the older builtin `less` would be used
        less
      ];

      programs.nix.target.user = true;
    };
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
    };
  };
}
