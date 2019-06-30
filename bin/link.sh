#!/bin/sh

#     __    _       __          __
#    / /   (_)___  / /__  _____/ /_
#   / /   / / __ \/ //_/ / ___/ __ \
#  / /___/ / / / / ,< _ (__  ) / / /
# /_____/_/_/ /_/_/|_(_)____/_/ /_/

XDG_CONFIG_HOME=$HOME/.config

for file in .??*; do
    [[ $file == ".git" ]] && continue
    ln -snfv $PWD/$file $HOME/$file
done

for file in */.??*; do
    [[ $(dirname $file) == "X11" ]] && continue
    ln -snfv $PWD/$file $HOME/$(basename $file)
done

for file in */link.sh; do
    [[ $(dirname $file) == "bin" ]] && continue
    ./$file
done
