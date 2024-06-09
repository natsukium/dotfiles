#!/bin/sh

if type git >/dev/null 2>&1; then
  git clone https://github.com/natsukium/dotfiles $HOME/.dotfiles
else
  tarball="https://github.com/natsukium/dotfiles/archive/main.tar.gz"
  curl -L "$tarball" | tar xvz
  mv -f dotfiles-main $HOME/.dotfiles
fi

cd $HOME/.dotfiles
make install_nix
