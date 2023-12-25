#!/bin/sh

install_nix() {
  if [ "$(uname)" = 'Darwin' ]; then
    curl -L https://nixos.org/nix/install | sh -s -- --daemon
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
  else
    curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
    # shellcheck disable=SC1091
    . "$HOME"/.nix-profile/etc/profile.d/nix.sh
  fi
  nix-channel --add https://nixos.org/channels/nixpkgs-unstable
  nix-channel --update
}

uninstall_nix() {
  if [ "$(uname)" = 'Darwin' ]; then
    sudo rm -rf /etc/nix /nix ~root/.nix-profile ~root/.nix-defexpr ~root/.nix-channels ~/.nix-profile ~/.nix-defexpr ~/.nix-channels
    sudo mv /etc/bashrc.backup-before-nix /etc/bashrc
    sudo mv /etc/bash.bashrc.backup-before-nix /etc/bash.bashrc
    sudo mv /etc/zshrc.backup-before-nix /etc/zshrc
    sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist
    sudo rm /Library/LaunchDaemons/org.nixos.nix-daemon.plist
  else
    sudo rm -rf /nix
  fi
}
