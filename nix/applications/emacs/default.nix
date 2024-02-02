{ pkgs, config, ... }:
let
  emacs = pkgs.emacsWithPackagesFromUsePackage {
    package =
      if pkgs.stdenv.isDarwin then
        config.nur.repos.natsukium.emacs-plus
      else
        pkgs.emacs.override { withPgtk = true; };
    config = ./init.el;
    extraEmacsPackages = epkgs: with epkgs; [ ];
  };
in
{
  programs.emacs = {
    enable = true;
    package = emacs;
  };

  xdg.configFile."emacs/init.el".source = config.lib.file.mkOutOfStoreSymlink "${config.programs.git.extraConfig.ghq.root}/github.com/natsukium/dotfiles/nix/applications/emacs/init.el";

  home.shellAliases = pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
    emacs = "${config.programs.emacs.package}/Applications/Emacs.app/Contents/MacOS/Emacs";
  };
}
