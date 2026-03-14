# This file is auto-generated from configuration.org.
# Do not edit directly.

{ pkgs, ... }:
{
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };
  my.programs.starship.enableFishAsyncPrompt = true;
}
