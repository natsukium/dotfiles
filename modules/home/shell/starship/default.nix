# This file is auto-generated from docs/shell.org.
# Do not edit directly.

{ pkgs, ... }:
{
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };
  my.programs.starship.enableFishAsyncPrompt = true;
}
