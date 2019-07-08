#!/bin/bash

# Install Plugin Manager, "vim-plug"
curl -fLo $XDG_DATA_HOME/vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo "Please :PlugInstall"
