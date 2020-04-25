#!/bin/sh

#    ______                       __
#   / ____/___  ________    _____/ /_
#  / /   / __ \/ ___/ _ \  / ___/ __ \
# / /___/ /_/ / /  /  __/ (__  ) / / /
# \____/\____/_/   \___(_)____/_/ /_/

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

if [ "$(uname)" = 'Linux' ]; then
    test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
    test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.bash_profile
fi

brew bundle --file=$PWD/homebrew/Brewfile-core

for file in installer/*.sh; do
    ./$file
done
