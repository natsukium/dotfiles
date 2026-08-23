# This file is auto-generated from configuration.org.
# Do not edit directly.

{ pkgs }:
{
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
}
