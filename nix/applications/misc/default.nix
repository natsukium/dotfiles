{ pkgs, config, ... }:
let
  nurpkgs = config.nur.repos.natsukium;
in
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
    gh.enable = true;
    jq.enable = true;
    lsd = {
      enable = true;
      enableAliases = true;
    };
    pdm = {
      enable = true;
      settings = {
        install.cache = true;
        venv.in_project = true;
      };
    };
    readline = {
      enable = true;
      variables = {
        completion-ignore-case = true;
      };
    };
    zoxide.enable = true;
  };
  services = {
    pueue.enable = true;
  };
  home.packages = with pkgs; [
    cachix
    coreutils
    fd
    ghq
    gnumake
    gnutar
    hydra-check
    nix-init
    nix-output-monitor
    nix-update
    nurpkgs.nixpkgs-review
    nkf
    podman
    ranger
    ripgrep
    wget
    zstd
  ];
  xdg.enable = true;
}
