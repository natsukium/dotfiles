#!/bin/sh

#################################################
###     _    _______ ______          __       ###
###    | |  / / ___// ____/___  ____/ /__     ###
###    | | / /\__ \/ /   / __ \/ __  / _ \    ###
###    | |/ /___/ / /___/ /_/ / /_/ /  __/    ###
###    |___//____/\____/\____/\__,_/\___/     ###
###                                           ###
#################################################

if [ "$(uname)" == 'Darwin' ]; then
    VSCODE_SETTING_PATH=$HOME/Library/Application\ Support/Code/User
elif [ "$(uname)" == 'Linux' ]; then
    VSCODE_SETTING_PATH=$HOME/.config/Code/User
fi

[[ ! -f $VSCODE_SETTING_PATH/settings.json ]] &&
    ln -sf "$PWD/vscode/settings.json" "$VSCODE_SETTING_PATH/settings.json"

extensions=(
    13xforever.language-x86-64-assembly
    arcticicestudio.nord-visual-studio-code
    auchenberg.vscode-browser-preview
    coenraads.bracket-pair-colorizer
    dbaeumer.vscode-eslint
    eamodio.gitlens
    fbosch.battery-indicator
    formulahendry.auto-close-tag
    github.vscode-pull-request-github
    ms-python.python
    ms-vscode.cpptools
    ms-vscode.csharp
    ms-vscode.go
    ms-vscode.vscode-typescript-tslint-plugin
    ms-vscode-remote.remote-containers
    ms-vscode-remote.remote-ssh
    ms-vscode-remote.remote-ssh-edit
    ms-vscode-remote.remote-ssh-explorer
    ms-vscode-remote.remote-wsl
    ms-vscode-remote.vscode-remote-extensionpack
    njpwerner.autodocstring
    octref.vetur
    peterjausovec.vscode-docker
    pkief.material-icon-theme
    rid9.datetime
    rust-lang.rust
    unity.unity-debug
    vadimcn.vscode-lldb
    visualstudioexptteam.vscodeintellicode
    vscodevim.vim
    wakatime.vscode-wakatime
)

echo 'Install VSCode Extensions'
for extension in ${extensions[@]}; do
    code --install-extension $extension
done
