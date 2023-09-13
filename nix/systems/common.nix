{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../modules/nix
  ];

  programs.nix.target.system = true;

  nix.gc =
    {
      automatic = true;
      options = "--delete-older-than 7d";
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux {
      dates = "weekly";
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      interval = {
        Weekday = 0;
        Hour = 0;
        Minute = 0;
      };
    };
}
