#!/usr/bin/env fish

# Plugin
if [ ! -f $XDG_CONFIG_HOME/fish/functions/fisher.fish ]
    curl https://git.io/fisher --create-dirs -sLo \
        $XDG_CONFIG_HOME/fish/functions/fisher.fish
end

fisher add \
    edc/bass \
    jorgebucaran/fish-nvm \
    kennethreitz/fish-pipenv \
    jethrokuan/fzf \
    jethrokuan/z \
    matchai/spacefish
