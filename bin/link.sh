#!/bin/sh

#     __    _       __          __
#    / /   (_)___  / /__  _____/ /_
#   / /   / / __ \/ //_/ / ___/ __ \
#  / /___/ / / / / ,< _ (__  ) / / /
# /_____/_/_/ /_/_/|_(_)____/_/ /_/

XDG_CONFIG_HOME=$HOME/.config

for file in .??*; do
    [ $file = ".git" ] && continue
    ln -snfv $PWD/$file $HOME/$file
done

for file in */.??*; do
    [ $(dirname $file) = "X11" ] && continue
    ln -snfv $PWD/$file $HOME/$(basename $file)
done

for file in */link.sh; do
    [ $(dirname $file) = "bin" ] && continue
    XDG_CONFIG_HOME=$HOME/.config ./$file
done

for dir in xdg_config_home/*; do
    [ ! -d $XDG_CONFIG_HOME/$(basename $dir) ] && mkdir -p $XDG_CONFIG_HOME/$(basename $dir)
    for file in $dir/*; do
        if [ $file = "xdg_config_home/fish/functions" ]; then
            [ ! -d $XDG_CONFIG_HOME/fish/functions ] && mkdir -p $XDG_CONFIG_HOME/fish/functions
            for function in $file/*; do
                ln -snfv $PWD/$function $XDG_CONFIG_HOME/fish/functions/$(basename $function)
            done
            continue
        fi
        ln -snfv $PWD/$file $XDG_CONFIG_HOME/$(basename $dir)/$(basename $file)
    done
done
