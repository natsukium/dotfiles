#!/bin/sh

if [ "$0" = "CI" ]; then
  if [ "$(uname)" = "Darwin" ]; then
    nix build .#darwinConfigurations.githubActions.system
    sudo rm /etc/nix/nix.conf
    ./result/sw/bin/darwin-rebuild switch --flake .#githubActions
  else
    nix build --impure --show-trace \
      .#nixosConfigurations.kilimanjaro.config.system.build.toplevel \
      .#nixosConfigurations.manyara.config.system.build.toplevel
  fi
	exit
fi

if type git >/dev/null 2>&1; then
  git clone https://github.com/natsukium/dotfiles $HOME/.dotfiles
else
  tarball="https://github.com/natsukium/dotfiles/archive/main.tar.gz"
  curl -L "$tarball" | tar xvz
  mv -f dotfiles-main $HOME/.dotfiles
fi

if test $REMOTE_CONTAINERS; then
  make container
else
  cd $HOME/.dotfiles
  make install_nix
fi
