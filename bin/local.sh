#!/bin/sh

if [ "$(uname)" == 'Darwin' ]; then
    $PWD/mac/setup.sh
elif [ "$(uname)" == 'Linux' ]; then
    :
fi

brew bundle --file=$PWD/homebrew/Brewfile-local

$PWD/vscode/init.sh
