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
        pkgsWithCuda = import inputs.nixpkgs-cuda {
          inherit (prev.stdenv.hostPlatform) system;
          config = {
            cudaSupport = true;
            allowUnfree = true;
          };
        };
        pkgs = import inputs.nixpkgs {
          inherit (prev.stdenv.hostPlatform) system;
          config.allowUnfree = true;
        };
      in
      {
        inherit (pkgsWithCuda) ollama;
        inherit (pkgs) onnxruntime;
        handy = prev.handy.override {
          inherit (pkgsWithCuda) onnxruntime;
        };
        calibre = pkgs.calibre;
      }
    );

  temporary-fix = final: prev: {
    afew = prev.afew.overridePythonAttrs {
      sphinxBuilders = "html man";
      makeWrapperArgs = [
        "--prefix"
        "PATH"
        ":"
        "${final.notmuch}/bin"
      ];
    };
    mozc = prev.mozc.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        (final.fetchpatch {
          name = "mozc-uic-leading-colons.patch";
          url = "https://github.com/google/mozc/commit/29c082a64b577b661694148760a2ae19817beb57.patch";
          hash = "sha256-Gft1mnLPSMexDMg/PVhwjUVl9D9g1cVGvVNgFmpK168=";
        })
      ];
    });
    toybox = prev.toybox.overrideAttrs (
      old:
      prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
        preBuild = (old.preBuild or "") + ''
          sed -i 's/^CONFIG_READAHEAD=y$/# CONFIG_READAHEAD is not set/' .config
        '';
      }
    );
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
