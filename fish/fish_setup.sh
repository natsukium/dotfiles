#!/usr/bin/env fish
# Install plugin manager "fisherman"
if [ ! -f $HOME/.config/fish/functions/fisher.fish ]
    curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs git.io/fisherman
end

# Install plugins
fisher z fzf edc/bass rafaelrinaldi/pure

# Add my functions to user dir
ln -sf ~/dotfiles/fish/alias/* ~/.config/fish/functions/
