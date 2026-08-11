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
      # renovate: datasource=github-releases depName=reizumii/parfait extractVersion=^v(?<version>.+)$
      version = "0.19";
      parfait = pkgs.fetchFromGitHub {
        owner = "reizumii";
        repo = "parfait";
        tag = "v${version}";
        hash = "sha256-6r4jQoqleNTLIA1G5N1dlVMWQe/kxTi6miLkuQxCDu4=";
      };
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
            extensions = sharedExtensions { inherit pkgs; };

            settings = {
              "extensions.autoDisableScopes" = 0;

              # parfait reads its own stylesheets from the profile, and paints icons through
              # context-fill, which is gated behind the second preference.
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
              "svg.context-properties.content.enabled" = true;

              "sidebar.verticalTabs" = true;
              "sidebar.visibility" = "hide-sidebar";

              "browser.translations.automaticallyPopup" = false;
              "layout.spellcheckDefault" = 0;
              "signon.rememberSignons" = false;

              "parfait.animations.enabled" = true;
              "parfait.blur.enabled" = true;
              "parfait.theme.roundness.preset" = 0;
              "parfait.window.borderless" = false;
              "parfait.bg.accent-color" = false;
              "parfait.bg.contrast" = 2;
              "parfait.bg.gradient" = false;
              "parfait.bg.opacity" = 4;
              "parfait.bg.transparent" = false;
              "parfait.tabs.groups.color" = false;
              "parfait.sidebar.width.preset" = 2;
              "parfait.toolbar.sidebar-gutter" = true;
              "parfait.toolbar.unified-sidebar" = true;
              "parfait.traffic-lights.enabled" = false;
              "parfait.traffic-lights.mono" = false;
              "parfait.urlbar.url.center" = false;
              "parfait.urlbar.results.compact" = false;
              "parfait.urlbar.search-mode.glow" = false;
              "parfait.new-tab.logo" = 1;
              "parfait.new-tab.bg.pattern" = false;
            };
          };
        };

        home.file."${config.programs.firefox.profilesPath}/natsukium/chrome".source = parfait;
      };
    };

  flake.modules.homeManager."zen-browser" =
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
            search = sharedSearch { inherit pkgs; };
            extensions = sharedExtensions { inherit pkgs; };

            settings = {
              "extensions.autoDisableScopes" = 0;

              "browser.translations.automaticallyPopup" = false;
              "layout.spellcheckDefault" = 0;
              "signon.rememberSignons" = false;
            };
          };
        };
      };
    };
}
