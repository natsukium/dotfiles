{ pkgs, ... }:

{
  xdg.configFile."python/pythonstartup".source = ./pythonstartup;
  programs.bash.profileExtra = ''
    export PYTHONSTARTUP=$XDG_CONFIG_HOME/python/pythonstartup
    [ ! -f $XDG_CACHE_HOME/python/history ] && mkdir -p $XDG_CACHE_HOME/python && touch $XDG_CACHE_HOME/python/history
  '';
}
