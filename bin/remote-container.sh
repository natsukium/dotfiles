#!/usr/bin/env bash

CODENAME=`cat /etc/os-release | grep VERSION_CODENAME | awk -F = '{print $2}'`

# Add fish repository
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 59FDA1CE1B84B3FAD89366C027557F056DC33CA5
echo "deb http://ppa.launchpad.net/fish-shell/release-3/ubuntu ${CODENAME} main" \
  | sudo tee /etc/apt/sources.list.d/fish.list

sudo apt update && sudo apt install -y \
  fish \
  fzf \
  vim

sh -c "$(curl -fsSL https://starship.rs/install.sh)" -s -f

bin/link.sh
