{ pkgs, ... }:

{
  programs = {
    fzf.enable = true;
    lsd.enable = true;
    readline = {
      enable = true;
      variables = {
        completion-ignore-case = true;
      };
    };
    bash.profileExtra = ''
      export LESSHISTFILE=-

      export INPUTRC=$XDG_CONFIG_HOME/readline/inputrc

      [ ! -d $XDG_CONFIG_HOME/wakatime ] && mkdir $XDG_CONFIG_HOME/wakatime
      export WAKATIME_HOME=$XDG_CONFIG_HOME/wakatime

      export DOCKER_CONFIG=$XDG_CONFIG_HOME/docker
      export MACHINE_STORAGE_PATH=$XDG_DATA_HOME/docker-machine
    '';
  };
  home.packages = with pkgs; [
    bottom
    coreutils
    ghq
    gnumake
    wget
  ];
}
