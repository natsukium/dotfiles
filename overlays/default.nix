{ inputs }:
{
  stable = final: prev: {
    inherit (inputs.nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system})
      # https://github.com/NixOS/nixpkgs/issues/339576
      bitwarden-cli
      ;
  };

  temporary-fix = final: prev: {
    claude-code = prev.claude-code.override {
      buildNpmPackage = prev.buildNpmPackage.override {
        # npm error sh: ./gyp-mac-tool: /usr/bin/env: bad interpreter: Operation not permitted
        nodejs = final.nodejs_20;
      };
    };
    python312 = prev.python312.override {
      packageOverrides = pyfinal: pyprev: {
        rapidocr-onnxruntime = pyprev.rapidocr-onnxruntime.overridePythonAttrs (_: {
          # segmentation fault
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
  };
}
