# This file is auto-generated from configuration.org.
# Do not edit directly.

{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.zen-browser;
in
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  options.my.programs.zen-browser = {
    enable = lib.mkEnableOption "Zen Browser";
  };

  config = lib.mkIf cfg.enable {
    programs.zen-browser = {
      enable = true;
      profiles.natsukium = {
        settings = {
          "extensions.autoDisableScopes" = 0;
        };

        search = {
          force = true;
          engines = {
            nix-packages = {
              name = "Nix Packages";
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "type";
                      value = "packages";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];

              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };

            nixos-wiki = {
              name = "NixOS Wiki";
              urls = [ { template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; } ];
              icon = "https://wiki.nixos.org/favicon.ico";
              definedAliases = [ "@nw" ];
            };

            noogle = {
              name = "noogle";
              urls = [ { template = "https://noogle.dev/q?term={searchTerms}"; } ];
              icon = "https://noogle.dev/favicon.png";
              definedAliases = [ "@noogle" ];
            };

            crates-io = {
              name = "crates.io";
              urls = [ { template = "https://crates.io/search?q={searchTerms}"; } ];
              icon = "https://crates.io/favicon.ico";
              definedAliases = [ "@crates" ];
            };

            npm = {
              name = "npm";
              urls = [ { template = "https://www.npmjs.com/search?q={searchTerms}"; } ];
              icon = "https://www.google.com/s2/favicons?domain=npmjs.com&sz=64";
              definedAliases = [ "@npm" ];
            };

            pypi = {
              name = "PyPI";
              urls = [ { template = "https://pypi.org/search/?q={searchTerms}"; } ];
              icon = "https://pypi.org/favicon.ico";
              definedAliases = [ "@pypi" ];
            };
          };
        };

        extensions = {
          packages =
            (with pkgs.firefox-addons; [
              bitwarden
              instapaper-official
              keepa
              onepassword-password-manager
              refined-github
              tampermonkey
              vimium
              wayback-machine
              zotero-connector
            ])
            ++ (with pkgs.my-firefox-addons; [
              adguard-adblocker
              calilay
              kiseppe-price-chart-kindle
            ]);
        };
      };
    };
  };
}
