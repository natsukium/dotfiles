{ ... }:
{
  flake.modules.homeManager.neovim =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.programs.neovim.enable = lib.mkEnableOption "neovim";

      config = lib.mkIf config.my.programs.neovim.enable {
        home.packages = [
          (pkgs.callPackage ./package.nix { })
          pkgs.neovim-remote
        ];
        home.sessionVariables.EDITOR = "nvim";
      };
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.neovim = pkgs.callPackage ./package.nix { };
    };
}
