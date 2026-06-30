# This file is auto-generated from configuration.org.
# Do not edit directly.

# Requires: inputs.vicinae
{ inputs, ... }:
{
  flake.modules.homeManager.vicinae =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.vicinae.homeManagerModules.default ];

      options.my.programs.vicinae.enable = lib.mkEnableOption "vicinae launcher";

      config = lib.mkIf config.my.programs.vicinae.enable {
        programs.vicinae = {
          enable = true;
          systemd.enable = true;
          launchd = {
            enable = true;
            environment.PATH = "${lib.makeBinPath [ pkgs.rbw ]}:/usr/bin:/bin:/usr/sbin:/sbin";
          };
          extensions = [
            (inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkVicinaeExtension {
              pname = "rbw";
              version = "0-unstable-2026-07-01";
              src = pkgs.fetchFromGitea {
                domain = "git.natsukium.com";
                owner = "natsukium";
                repo = "vicinae-extension-rbw";
                rev = "66444c3c02bd4121f7127ced30dfc5b1d29b5bcf";
                hash = "sha256-jhbn2eICx7Sf8lm7d5/6cYM3Cl1b/llQyVKuAQvWVWE=";
              };
            })
          ];
          settings = {
            keybinding = "emacs";
            theme.dark.name = "nord";
          };
        };
      };
    };
}
