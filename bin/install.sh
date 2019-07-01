#!/bin/sh

#     ____           __        ____        __
#    /  _/___  _____/ /_____ _/ / /  _____/ /_
#    / // __ \/ ___/ __/ __ `/ / /  / ___/ __ \
#  _/ // / / (__  ) /_/ /_/ / / /_ (__  ) / / /
# /___/_/ /_/____/\__/\__,_/_/_/(_)____/_/ /_/

if type git >/dev/null 2>&1; then
    git clone https://github.com/natsukium/dotfiles $HOME/.dotfiles
else
    tarball="https://github.com/natsukium/dotfiles/archive/master.tar.gz"
    curl -L "$tarball" | tar xvz
    mv -f dotfiles-master $HOME/.dotfiles

    echo "Please install git."
    exit
fi

cd $HOME/.dotfiles
make minimum

if [ $1 == "--local" ]; then
    make local
fi
