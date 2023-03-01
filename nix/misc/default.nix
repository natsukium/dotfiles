{pkgs, ...}: {
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
      nkf
      podman
      ripgrep
      wget
      zstd
    ]
    ++ lib.optional stdenv.isDarwin qemu;
  xdg.enable = true;
}
