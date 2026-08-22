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
    fzf = {
      enable = true;
      # Atuin is sourced after fzf in fish and nushell and rebinds Ctrl-R, so
      # fzf's own binding there is dead weight and trips Home Manager's conflict
      # warning.
      historyWidget = {
        fish.command = "";
        nushell.command = "";
      };
    };
    jq.enable = true;
    lsd.enable = true;
    nix-index.enable = true;
    zoxide.enable = true;
  };
  my.services.pueue.enable = true;
  home.packages = with pkgs; [
    ast-grep
    attic-client
    cachix
    coreutils
    fd
    forgejo-cli
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
