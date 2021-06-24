#!/usr/bin/env bash

sudo apt install -y \
  fish \
  fzf \
  vim

sh -c "$(curl -fsSL https://starship.rs/install.sh)"

bin/link.sh
