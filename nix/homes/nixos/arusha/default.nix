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
      imports = [
        ../../common.nix
        ../../../modules/nix
      ];
      programs.nix.target.user = true;
      home.packages = [ pkgs.wslu ];
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
