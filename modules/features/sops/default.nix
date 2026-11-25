{ ... }:
{
  flake.modules.homeManager.sops =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

      my.programs.dotcli.plugins.age = {
        source = ./dotcli;
        settings = {
          inherit (config.sops.age) keyFile;
          secretsDir = config.sops.defaultSymlinkPath;
          service = "sops-nix";
          ageKeygen = lib.getExe' pkgs.age "age-keygen";
          sops = lib.getExe pkgs.sops;
        };
      };
    };
}
