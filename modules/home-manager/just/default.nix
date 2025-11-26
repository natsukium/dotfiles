{ config, lib, ... }:
{
  options.my.programs.just = {
    enableEnhancedCompletion = lib.mkEnableOption "enhanced just completion with module support for fish";
  };

  config = lib.mkIf config.my.programs.just.enableEnhancedCompletion {
    xdg.configFile."fish/completions/just.fish".source = ./completions.fish;
  };
}
