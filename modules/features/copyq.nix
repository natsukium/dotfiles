{ ... }:
{
  flake.modules.homeManager.copyq =
    {
      config,
      options,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.copyq;
      inherit (config.lib) appIdentity;
      app = appIdentity.stabilizeApp cfg.package;
    in
    {
      options.my.services = { inherit (options.services) copyq; };
      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          (lib.mkIf pkgs.stdenv.hostPlatform.isLinux { services = { inherit (config.my.services) copyq; }; })

          (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
            home.packages = [ app ];
            launchd.agents.copyq = {
              enable = true;
              config = {
                ProgramArguments = [ "${app}/Applications/CopyQ.app/Contents/MacOS/CopyQ" ];
                KeepAlive = true;
                RunAtLoad = true;
              };
            };
          })
        ]
      );
    };
}
