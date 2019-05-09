#!/usr/bin/env fish
# Install plugin manager "fisherman"
if [ ! -f $HOME/.config/fish/functions/fisher.fish ]
    curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish
end

# Install plugins
fisher add z fzf edc/bass rafaelrinaldi/pure

# Add my functions to user dir
ln -sf ~/dotfiles/fish/alias/* ~/.config/fish/functions/
