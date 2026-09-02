# This file is auto-generated from configuration.org.
# Do not edit directly.

{ inputs }:
{
  stable = final: prev: {
  };

  cuda =
    final: prev:
    prev.lib.optionalAttrs (prev.config.cudaSupport or false) (
      let
        pkgs = import inputs.nixpkgs-cuda {
          inherit (prev.stdenv.hostPlatform) system;
          config = {
            cudaSupport = true;
            allowUnfree = true;
          };
        };
      in
      {
        inherit (pkgs) onnxruntime ollama;
      }
    );

  temporary-fix = final: prev: {
    handy = prev.handy.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or [ ]) ++ [ ./handy-retry-without-reasoning.patch ];
    });
  };

  pre-release = final: prev: { };

  patches = final: prev: {
    gh-dash =
      (final.writeShellApplication {
        name = "gh-dash";
        text = ''
          LANG=C.UTF-8 ${final.lib.getExe prev.gh-dash} "$@"
        '';
      }).overrideAttrs
        { pname = "gh-dash"; };
    inherit (final.callPackage ../pkgs/mkShim { }) mkShim commandLineToolsShim;
  };
}
