{ pkgs, ... }:

{
  programs.direnv =
    {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      nix-direnv.enable = true;
    };
}
