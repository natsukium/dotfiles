#!/bin/sh
 
# Install Homebrew
if type brew >/dev/null 2>&1; then
    :
else
    echo 'Install Homebrew🍺'
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Install CUI Tools
cuitools=(
    bash
    coreutils
    fish
    fzf
    ranger
    screenfetch
    tmux
    wget
)

echo 'Install CUI Tools'
for tool in ${cuitools[@]}; do
    brew install ${tool}
done

# Install GUI Tools
guitools=(
    amethyst
    docker
    dropbox
    google-chrome
    hyper
    kindle
    slack
    visual-studio-code
) 

echo 'Install GUI Tools'
for tool in ${guitools[@]}; do
    brew cask install ${tool}
done
