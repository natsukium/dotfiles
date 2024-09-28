{
  config,
  lib,
  pkgs,
  stdenv,
  ...
}:
let
  nvidia-wsl =
    { stdenv, pkgs }:
    stdenv.mkDerivation {
      name = "nvidia-wsl";
      src = /usr/lib/wsl/lib; # Because of this, you must evaluate with --impure
      installPhase = ''
        install -Dm644 $src/lib* -t $out/lib
        install -Dm755 $src/nvidia-smi -t $out/bin
      '';
      phases = [ "installPhase" ];
    };
in
with builtins;
with lib;
{
  options.wsl.docker-native = with types; {
    enableNvidia = mkEnableOption "Nvidia Container Toolkit integration";
  };

  config =
    let
      cfg = config.wsl.docker-native;
    in
    mkIf (config.wsl.enable && cfg.enableNvidia) {
      virtualisation.docker.enableNvidia = true;
      hardware.graphics.extraPackages = [ (pkgs.callPackage nvidia-wsl { }) ];
    };
}
