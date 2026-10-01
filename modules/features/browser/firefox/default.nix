# This file is auto-generated from configuration.org.
# Do not edit directly.

{ ... }:
let
  sharedSearch = import ./search.nix;
  sharedExtensions = import ./extensions.nix;
in
{
  flake.modules.homeManager.firefox =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.firefox;
      parfait = pkgs.callPackage ./parfait.nix { };
      workContainerId = 1;
    in
    {
      options.my.programs.firefox = {
        enable = lib.mkEnableOption "Firefox";
      };

      config = lib.mkIf cfg.enable {
        programs.firefox = {
          enable = true;
          configPath = lib.mkIf pkgs.stdenv.hostPlatform.isLinux "${config.xdg.configHome}/mozilla/firefox";
          profiles.natsukium = {
            search = sharedSearch { inherit pkgs; };
            extensions = sharedExtensions { inherit pkgs; } // {
              settings."containerise@kinte.sh" = {
                force = true;
                settings =
                  let
                    work = host: {
                      inherit host;
                      cookieStoreId = "firefox-container-${toString workContainerId}";
                      containerName = "work";
                      enabled = true;
                    };
                  in
                  {
                    "map=github.com/orgs/attmcojp" = work "github.com/orgs/attmcojp";
                    "map=github.com/attmcojp" = work "github.com/attmcojp";
                  };
              };
            };

            containers.work = {
              id = workContainerId;
              color = "red";
              icon = "briefcase";
            };
            containersForce = true;

            settings =
              let
                parfaitSrc = fetchTarball {
                  inherit (parfait) url;
                  sha256 = parfait.outputHash;
                };
                parfaitDefaults = lib.pipe "${parfaitSrc}/user.js" [
                  builtins.readFile
                  (lib.splitString "\n")
                  (map (builtins.match ''user_pref\("([^"]+)", (.*)\);''))
                  (lib.filter (m: m != null))
                  (map (m: lib.nameValuePair (lib.elemAt m 0) (builtins.fromJSON (lib.elemAt m 1))))
                  lib.listToAttrs
                ];
                parfaitOverrides = {
                  "parfait.theme.blur.enabled" = true;
                };
                staleOverrides = lib.attrNames (removeAttrs parfaitOverrides (lib.attrNames parfaitDefaults));
              in
              lib.throwIf (staleOverrides != [ ])
                "parfait's user.js no longer defines ${lib.concatStringsSep ", " staleOverrides}"
                (
                  parfaitDefaults
                  // parfaitOverrides
                  // {
                    "extensions.autoDisableScopes" = 0;

                    "sidebar.verticalTabs" = true;
                    "sidebar.visibility" = "hide-sidebar";

                    "browser.translations.automaticallyPopup" = false;
                    "layout.spellcheckDefault" = 0;
                    "signon.rememberSignons" = false;
                  }
                );
          };
        };

        home.file."${config.programs.firefox.profilesPath}/natsukium/chrome".source = parfait;
      };
    };
}
