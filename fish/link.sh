#!/bin/sh

CONFIG_ROOT=$XDG_CONFIG_HOME/fish
[[ ! -d $CONFIG_ROOT ]] && mkdir -p $CONFIG_ROOT/functions

ln -snfv $PWD/fish/alias/* $CONFIG_ROOT/functions
