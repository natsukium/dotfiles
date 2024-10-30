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
      dockutil
      # https://github.com/NixOS/nixpkgs/issues/339576
      bitwarden-cli
      ;
  };

  temporary-fix = final: prev: {
    python3 = prev.python3.override {
      packageOverrides = pyfinal: pyprev: {
        pyreqwest-impersonate = pyprev.pyreqwest-impersonate.overridePythonAttrs (oldAttrs: {
          # https://github.com/NixOS/nixpkgs/issues/349432#issuecomment-2423129494
          postFixup =
            (oldAttrs.postFixup or "")
            + final.lib.optionalString final.stdenv.hostPlatform.isLinux ''
              ${final.patchelf}/bin/patchelf --add-rpath ${final.gcc-unwrapped.lib}/lib --add-needed libstdc++.so.6 $out/lib/python3.12/site-packages/pyreqwest_impersonate/pyreqwest_impersonate.cpython-312-x86_64-linux-gnu.so
            '';
        });
        opentelemetry-proto = pyprev.opentelemetry-proto.overridePythonAttrs (oldAttrs: {
          pythonRelaxDeps = (oldAttrs.pythonRelaxDeps or [ ]) ++ [ "protobuf" ];
        });
      };
    };
  };

  pre-release = final: prev: {
    terraform = prev.terraform.overrideAttrs (oldAttrs: {
      version = "1.10.0-alpha20241023";
      src = final.fetchFromGitHub {
        owner = "hashicorp";
        repo = "terraform";
        rev = "v1.10.0-alpha20241023";
        hash = "sha256-LCFHumML7U5nvN1e2HItFMPBVk60sBEH6kHFXZNjn94=";
      };
      vendorHash = "sha256-69Q224SP6P1HRD5UZe6IMow/Dtt1GbppDP3fbUYwYxg=";
    });
  };
}
