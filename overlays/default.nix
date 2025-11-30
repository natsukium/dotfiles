{ inputs }:
{
  stable = final: prev: {
    inherit (inputs.nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system})
      hercules-ci-agent
      ;
  };

  temporary-fix = final: prev: {
    python313 = prev.python313.override {
      packageOverrides = pyfinal: pyprev: {
        rapidocr-onnxruntime = pyprev.rapidocr-onnxruntime.overridePythonAttrs (_: {
          doCheck = false;
        });
        lxml-html-clean = pyprev.lxml-html-clean.overridePythonAttrs (_: {
          doCheck = false;
        });
      };
    };
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
