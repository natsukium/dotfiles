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
        inherit (pkgsWithCuda) onnxruntime ollama;
        firefox-unwrapped = prev.firefox-unwrapped.override {
          inherit (pkgs) onnxruntime;
        };
        calibre = pkgs.calibre;
      }
    );

  temporary-fix = final: prev: {
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
