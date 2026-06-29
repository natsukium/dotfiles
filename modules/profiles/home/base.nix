{ inputs, ... }:
{
  imports = [
    ../../home/bash
    inputs.self.modules.homeManager.fish
    ../../home/nix
    ../../home/nushell
    ../../home/starship
  ];

  my.programs.fish.enable = true;
}
