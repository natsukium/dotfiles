#!/bin/sh
if [ "$(uname)" = 'Darwin' ]; then
    VSCODE_SETTING_PATH=$HOME/Library/Application\ Support/Code/User
elif [ "$(uname)" = 'Linux' ]; then
    VSCODE_SETTING_PATH=$HOME/.config/Code/User
fi
[ ! -d $VSCODE_SETTING_PATH ] && mkdir -p $VSCODE_SETTING_PATH

ln -snfv $PWD/vscode/settings.json "$VSCODE_SETTING_PATH/settings.json"
