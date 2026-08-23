{ ... }:
{
  flake.modules.homeManager.zotero =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs) stdenv;
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

      zotero = pkgs.zotero;
      better-bibtex = pkgs.callPackage ./better-bibtex.nix { inherit zotero; };
      user-js = ''
        user_pref("extensions.autoDisableScopes", 0);
      '';
    in
    {
      options.my.programs.zotero.enable = lib.mkEnableOption "zotero";

      config = lib.mkIf config.my.programs.zotero.enable {
        home.packages = [ zotero ];

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
      };
    };
}
