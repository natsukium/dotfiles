{ specialArgs, ... }:
let
  inherit (specialArgs) username;
in
{
  imports = [
    ../../modules/profiles/home/generic-linux.nix
    ../common.nix
  ];

  targets.genericLinux.enable = true;
  home = {
    inherit username;
    homeDirectory = "/home/${username}";
  };
  nixpkgs.config.allowUnfreePredicate = pkg: true;
}
