{ specialArgs, ... }:
let
  inherit (specialArgs) username;
in
{
  imports = [
    ../common.nix
    ../../modules/nix
  ];

  programs.nix.target.otherDistroUser = true;

  targets.genericLinux.enable = true;
  home = {
    inherit username;
    homeDirectory = "/home/${username}";
  };
  nixpkgs.config.allowUnfreePredicate = pkg: true;
}
