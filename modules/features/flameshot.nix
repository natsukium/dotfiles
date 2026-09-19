{ ... }:
{
  flake.modules.homeManager.flameshot =
    {
      config,
      options,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.flameshot;
      appIdentity = pkgs.callPackage inputs.nix-mac-app-identity { };
      app = appIdentity.stabilizeApp cfg.package;
      iniFormat = pkgs.formats.ini { };
      iniFile = iniFormat.generate "flameshot.ini" cfg.settings;
    in
    {
      options.my.services = { inherit (options.services) flameshot; };
      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
            services = { inherit (config.my.services) flameshot; };
          })

          (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
            home.packages = [ app ];

            xdg.configFile = lib.mkIf (cfg.settings != { }) {
              "flameshot/flameshot.ini".source = iniFile;
            };

            launchd.agents.flameshot = {
              enable = true;
              config = {
                ProgramArguments = [ "${app}/bin/flameshot" ];
                KeepAlive = true;
                RunAtLoad = true;
              };
            };
          })
        ]
      );
    };
}
