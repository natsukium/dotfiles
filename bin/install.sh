#!/bin/sh

if [ "$0" = "CI" ]; then
  if [ "$(uname)" = "Darwin" ]; then
    nix build .#darwinConfigurations.githubActions.system
    export HOME_MANAGER_BACKUP_EXT=backup
    ./result/sw/bin/darwin-rebuild switch --flake .#githubActions
  else
    nix build .#homeConfigurations.githubActions.activationPackage
    HOME_MANAGER_BACKUP_EXT=backup ./result/activate --flake .#githubActions
  fi
	exit
fi

if type git >/dev/null 2>&1; then
  git clone https://github.com/natsukium/dotfiles $HOME/.dotfiles
else
  tarball="https://github.com/natsukium/dotfiles/archive/master.tar.gz"
  curl -L "$tarball" | tar xvz
  mv -f dotfiles-master $HOME/.dotfiles
fi

if test $REMOTE_CONTAINERS; then
  make container
else
  cd $HOME/.dotfiles
  . bin/install_nix.sh
  install_nix
  install_nix_unstable
  install_home_manager
fi
