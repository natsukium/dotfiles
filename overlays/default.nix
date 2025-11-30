{ inputs }:
{
  stable = final: prev: {
    inherit (inputs.nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system})
      # https://github.com/NixOS/nixpkgs/pull/463879
      hercules-ci-agent
      ;
  };

  temporary-fix = final: prev: {
    python313 = prev.python313.override {
      packageOverrides = pyfinal: pyprev: {
        rapidocr-onnxruntime = pyprev.rapidocr-onnxruntime.overridePythonAttrs (_: {
          # segmentation fault
          doCheck = false;
        });
        lxml-html-clean = pyprev.lxml-html-clean.overridePythonAttrs (_: {
          # test failures with libxml2 2.14
          # https://github.com/fedora-python/lxml_html_clean/issues/24
          doCheck = false;
        });
      };
    };
  };

  pre-release = final: prev: { };

  patches = final: prev: {
    # preview pane is corrupted when `LANG=ja_JP.UTF-8`
    # https://github.com/dlvhdr/gh-dash/issues/316
    gh-dash =
      (final.writeShellApplication {
        name = "gh-dash";
        text = ''
          LANG=C.UTF-8 ${final.lib.getExe prev.gh-dash} "$@"
        '';
      }).overrideAttrs
        # workaround for `attribute 'pname' missing
        # at /nix/store/cj9d242mdxb7n217gs9x2yfxpydlg2q6-source/modules/programs/gh.nix:160:9:
        #  159|       source = pkgs.linkFarm "gh-extensions" (builtins.map (p: {
        #  160|         name = p.pname;
        #     |         ^
        #  161|         path = "${p}/bin";
        #  error: attribute 'pname' missing
        { pname = "gh-dash"; };

    inherit (final.callPackage ../pkgs/mkShim { }) mkShim commandLineToolsShim;
  };
}
