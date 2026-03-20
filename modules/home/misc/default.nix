{ inputs, pkgs, ... }:
{
  ext.xdg.enable = true;
  programs = {
    bat.enable = true;
    btop = {
      enable = true;
      settings = {
        vim_keys = true;
      };
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    fzf.enable = true;
    jq.enable = true;
    lsd.enable = true;
    nix-index.enable = true;
    readline = {
      enable = true;
      variables = {
        completion-ignore-case = true;
      };
    };
    zoxide.enable = true;
  };
  my.services.pueue.enable = true;
  home.packages = with pkgs; [
    ast-grep
    attic-client
    cachix
    coreutils
    fd
    gnumake
    gnutar
    hydra-check
    jnv
    maestral
    nix-init
    nix-output-monitor
    nix-update
    nixpkgs-review
    nkf
    ranger
    ripgrep
    wget
    zstd
  ];
  xdg.enable = true;
}
