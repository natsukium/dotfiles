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
          overlays = [
            (pfinal: pprev: {
              speechd = pprev.speechd.overrideAttrs (old: {
                nativeBuildInputs = old.nativeBuildInputs ++ [ pfinal.python3 ];
              });
              pythonPackagesExtensions = pprev.pythonPackagesExtensions ++ [
                (_: pyprev: {
                  pyopenjtalk-plus = pyprev.pyopenjtalk-plus.overridePythonAttrs (old: {
                    patches = (old.patches or [ ]) ++ [
                      (pfinal.fetchpatch {
                        name = "fix-cython-3.3.0.patch";
                        url = "https://github.com/tsukumijima/pyopenjtalk-plus/commit/90b644f9e9d397882e6eafe4dcd1843a4fde6a63.patch";
                        includes = [ "tests/test_frontend.py" ];
                        hash = "sha256-Jb7T/bRUHxqwBLwV6xYC/teaFHm5GmqJxA7sCX+oiNI=";
                      })
                    ];
                  });
                })
              ];
            })
          ];
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

  pre-release = final: prev: {
    mcp-grafana = prev.mcp-grafana.overrideAttrs (
      finalAttrs: _: {
        version = "1.4.2";
        src = final.fetchFromGitHub {
          owner = "grafana";
          repo = "mcp-grafana";
          tag = "v${finalAttrs.version}";
          hash = "sha256-MUqVsrfjlDLanWzXzMVGYhlXjF23ovGm/ocz7A4vrxw=";
        };
        vendorHash = "sha256-y/Hk1hDQ00wHqTOcaoKVvz2PgF0ZiwHartbuF7qEkXc=";
        checkFlags = [ "-skip=TestFetchDashboardViaK8s_V2Refetch" ];
      }
    );
  };

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
