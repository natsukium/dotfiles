#!/bin/sh

install_nix() {
  if [ "$(uname)" = 'Darwin' ]; then
    sh <(curl -L https://nixos.org/nix/install) --darwin-use-unencrypted-nix-store-volume
  else
    curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
  fi
  . $HOME/.nix-profile/etc/profile.d/nix.sh
  nix-channel --add https://nixos.org/channels/nixpkgs-unstable
  nix-channel --update
}

install_nix_unstable() {
  nix-env -iA nixpkgs.nixUnstable
}

install_home_manager() {
  nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
  nix-channel --update
  export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH
  nix-shell '<home-manager>' -A install
}

uninstall_nix() {
  sudo rm -rf /nix
}
