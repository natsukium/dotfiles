# https://github.com/nix-community/home-manager/issues/1341#issuecomment-1870352014
{ inputs, pkgs, ... }:

{
  # Install MacOS applications to the user Applications folder.
  home.extraActivationPath = with pkgs; [
    rsync
    gawk
  ];
  home.activation.trampolineApps = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${builtins.readFile ./trampoline-apps.sh}
    fromDir="$HOME/Applications/Home Manager Apps"
    toDir="$HOME/Applications/Home Manager Trampolines"
    sync_trampolines "$fromDir" "$toDir"
  '';
}
