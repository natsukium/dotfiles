{pkgs, ...}: {
  imports = [../modules/pdm.nix];
  programs = {
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
    bash.profileExtra = ''
      export LESSHISTFILE=-

      export INPUTRC=$XDG_CONFIG_HOME/readline/inputrc

      [ ! -d $XDG_CONFIG_HOME/wakatime ] && mkdir $XDG_CONFIG_HOME/wakatime
      export WAKATIME_HOME=$XDG_CONFIG_HOME/wakatime

      export DOCKER_CONFIG=$XDG_CONFIG_HOME/docker
      export MACHINE_STORAGE_PATH=$XDG_DATA_HOME/docker-machine
    '';
  };
  services = {
    ssh-agent.enable = pkgs.stdenv.isLinux;
    gpg-agent.enable = pkgs.stdenv.isLinux;
  };
  home.packages = with pkgs;
    [
      bitwarden-cli
      bottom
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
      nixpkgs-review
      nkf
      pinentry-curses
      pipx
      podman
      ripgrep
      wget
      zstd
    ]
    ++ lib.optional stdenv.isDarwin qemu;
  xdg.enable = true;
}
