# This file is auto-generated from configuration.org.
# Do not edit directly.

{ pkgs }:
{
  packages =
    (with pkgs.firefox-addons; [
      bitwarden
      instapaper-official
      keepa
      onepassword-password-manager
      refined-github
      vimium
      violentmonkey
      wayback-machine
      zotero-connector
    ])
    ++ (with pkgs.my-firefox-addons; [
      adguard-adblocker
      calilay
      kiseppe-price-chart-kindle
    ]);
}
