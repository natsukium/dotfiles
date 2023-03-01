{pkgs, ...}: {
  imports = [./common.nix];
  home.packages = [pkgs.wslu];
  programs.bash.profileExtra = ''
    export WIN_HOME=$(wslpath $(wslvar USERPROFILE))
  '';
}
