#!/usr/bin/env fish
# Install plugin manager "fisherman"
curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs git.io/fisherman

# Install plugins
fisher z fzf edc/bass rafaelrinaldi/pure

# Add my functions to user dir
ln -sf ~/dotfiles/fish/alias/* ~/.config/fish/functions/
