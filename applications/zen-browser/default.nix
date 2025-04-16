{
  inputs,
  config,
  pkgs,
  ...
}:
let
  inherit (pkgs) lib stdenv;
in
{
  programs.zen-browser =
    {
      enable = true;
      profiles.natsukium = {
        settings = { };
        search = {
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
              iconMapObj."16" = "https://wiki.nixos.org/favicon.ico";
              definedAliases = [ "@nw" ];
            };
          };
        };
      };
    }
    // lib.optionalAttrs stdenv.hostPlatform.isDarwin {
      package = pkgs.zen-browser;
    };
}
