{ pkgs, ... }:
let
  inherit (pkgs) lib stdenv;
  profiles = {
    "Profile0" = {
      Name = "natsukium";
      Path = if stdenv.hostPlatform.isDarwin then "Profiles/natsukium" else "natsukium";
      IsRelative = 1;
      Default = 1;
    };
    General = {
      StartWithLastProfile = 1;
      Version = 2;
    };
  };

  profilesIni = lib.generators.toINI { } profiles;

  configPath =
    if stdenv.hostPlatform.isDarwin then "Library/Application Support/Zotero" else ".zotero/zotero";

  profilesPath = if stdenv.hostPlatform.isDarwin then "${configPath}/Profiles" else configPath;

  better-bibtex =
    let
      # renovate: datasource=github-releases depName=retorquere/zotero-better-bibtex extractVersion=^v(?<version>.+)$
      version = "9.0.55";
    in
    pkgs.fetchurl {
      url = "https://github.com/retorquere/zotero-better-bibtex/releases/download/v${version}/zotero-better-bibtex-${version}.xpi";
      hash = "sha256-LZFOuxdMLFkOz/dBppA/GXkGW0J0DzAdk47Cy2wD5NY=";
    };
  user-js = ''
    user_pref("extensions.autoDisableScopes", 0);
  '';
in
{
  home.packages = [ pkgs.zotero ];

  home.file = {
    "${configPath}/profiles.ini" = {
      text = profilesIni;
    };

    "${profilesPath}/natsukium/extensions/better-bibtex@iris-advies.com.xpi" = {
      source = better-bibtex;
    };

    "${profilesPath}/natsukium/user.js" = {
      text = user-js;
    };
  };
}
