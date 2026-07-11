{ ... }:
{
  my.programs.fish.enable = true;
  my.programs.bash.enable = true;
  my.programs.nushell.enable = true;
  my.programs.starship = {
    enable = true;
    enableFishAsyncPrompt = true;
  };
  my.nix.enable = true;
}
