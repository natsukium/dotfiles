#!/bin/sh

#     __    _       __          __
#    / /   (_)___  / /__  _____/ /_
#   / /   / / __ \/ //_/ / ___/ __ \
#  / /___/ / / / / ,< _ (__  ) / / /
# /_____/_/_/ /_/_/|_(_)____/_/ /_/

XDG_CONFIG_HOME=$HOME/.config

echo .??* | tr " " "\n" | grep -v git | xargs -I{} ln -snfv $PWD/{} $HOME/{}

echo */.??* | tr " " "\n" | grep -v X11 | xargs -I{} ln -snfv $PWD/{} $HOME/{}

echo */link.sh | tr " " "\n" | grep -v bin | xargs sh

find xdg_config_home -type d | sed -e "s|xdg_config_home|$XDG_CONFIG_HOME|g" | xargs mkdir -p
find xdg_config_home -type f | sed -e "s|xdg_config_home/||g" | xargs -I{} ln -snfv $PWD/xdg_config_home/{} $XDG_CONFIG_HOME/{}
