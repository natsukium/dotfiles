#!/bin/sh

#     ____      _ __         __
#    /  _/___  (_) /_  _____/ /_
#    / // __ \/ / __/ / ___/ __ \
#  _/ // / / / / /__ (__  ) / / /
# /___/_/ /_/_/\__(_)____/_/ /_/

for file in */init.*sh; do
    [[ $file == "vscode/init.sh" ]] && continue
    ./$file
done
