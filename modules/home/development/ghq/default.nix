{ config, ... }:
{
  my.programs.ghq = {
    root = "${config.home.homeDirectory}/src/private";
  };
}
