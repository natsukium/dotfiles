{ inputs }:
{
  stable = final: prev: {
    inherit (inputs.nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system})
      # swift is broken on darwin as of 2024-06
      # https://github.com/NixOS/nixpkgs/issues/320900
      swift
      swiftPackages
      swiftpm
      swiftpm2nix
      # https://github.com/NixOS/nixpkgs/issues/339576
      bitwarden-cli
      ;
  };

  temporary-fix = final: prev: {
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
}
