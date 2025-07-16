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

  better-bibtex-version = "7.0.38";
  better-bibtex = pkgs.fetchurl {
    url = "https://github.com/retorquere/zotero-better-bibtex/releases/download/v${better-bibtex-version}/zotero-better-bibtex-${better-bibtex-version}.xpi";
    hash = "sha256-tdjRFMmnrst6JTNP5yCuDLX2pDIS9olAKEnyHp8m8WE=";
  };
in
{
  home.packages = [ pkgs.zotero ];
  home.file."Library/Application Support/Zotero/profiles.ini" =
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
      {
        text = profilesIni;
      };
  home.file.".zotero/profiles.ini" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    text = profilesIni;
  };
  home.file."Library/Application Support/Zotero/Profiles/natsukium/extensions/better-bibtex@iris-advies.com.xpi" =
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin { source = better-bibtex; };
  home.file.".zotero/natsukium/extensions/better-bibtex@iris-advies.com.xpi" =
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux
      { source = better-bibtex; };
}
