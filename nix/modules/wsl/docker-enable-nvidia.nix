{
  config,
  lib,
  pkgs,
  stdenv,
  ...
}: let
  nvidia-wsl = {
    stdenv,
    pkgs,
  }:
    stdenv.mkDerivation {
      name = "nvidia-wsl";

      __propagatedImpureHostDeps = [
        "/usr/lib/wsl/lib"
      ];

      # src = /usr/lib/wsl/lib; # Because of this, you must evaluate with --impure
      installPhase = ''
        runHook preInstall
        
        mkdir -p $out/{lib,bin}
        ln -s /usr/lib/wsl/lib/lib* $out/lib/
        ln -s /usr/lib/wsl/lib/nvidia-smi $out/bin/

        runHook postInstall
      '';
      phases = ["installPhase"];
    };
in
  with builtins;
  with lib; {
    options.wsl.docker-native = with types; {
      enableNvidia = mkEnableOption "Nvidia Container Toolkit integration";
    };

    config = let
      cfg = config.wsl.docker-native;
    in
      mkIf (config.wsl.enable && cfg.enableNvidia) {
        virtualisation.docker.enableNvidia = true;
        hardware.opengl.extraPackages = [(pkgs.callPackage nvidia-wsl {stdenv = pkgs.stdenvNoCC;})];
      };
  }
