{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.nix;
in {
  options.programs.nix.target = {
    system = mkEnableOption "";
    user = mkEnableOption "";
    otherDistroUser = mkEnableOption "";
    nvidia = mkEnableOption "";
  };

  config = mkMerge [
    (mkIf (cfg.target.system or cfg.target.otherDistroUser) {
      nix = {
        settings = {
          auto-optimise-store = true;
          experimental-features = ["nix-command" "flakes"];
          substituters =
            [
              "https://natsukium.cachix.org"
            ]
            ++ lib.optionals cfg.target.nvidia [
              "https://cuda-maintainers.cachix.org"
            ];
          trusted-public-keys =
            [
              "natsukium.cachix.org-1:STD7ru7/5+KJX21m2yuDlgV6PnZP/v5VZWAJ8DZdMlI="
            ]
            ++ lib.optionals cfg.target.nvidia [
              "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
            ];
          trusted-users =
            ["root" "@wheel"]
            ++ optional pkgs.stdenv.isDarwin "@admin";
          sandbox = true;
          warn-dirty = false;
        };
      };
    })
    (mkIf (cfg.target.user or cfg.target.otherDistroUser) {
      nix.settings.use-xdg-base-directories = true;
    })
  ];
}