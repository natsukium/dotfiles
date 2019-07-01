#!/bin/sh

CONFIG_ROOT=$XDG_CONFIG_HOME/alacritty
[[ ! -d $CONFIG_ROOT ]] && mkdir -p $CONFIG_ROOT

ln -snfv $PWD/alacritty/alacritty.yml \
    $CONFIG_ROOT/alacritty.yml
