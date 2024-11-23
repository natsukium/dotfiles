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
    # reduce needless heavy rebuild
    open-webui = prev.open-webui.override { python311 = final.python3; };
    python3 = prev.python3.override {
      packageOverrides = pyfinal: pyprev: {
        pyhanko = pyprev.pyhanko.overridePythonAttrs (_: {
          doCheck = false;
        });
      };
    };
  };

  pre-release = final: prev: {
    terraform = prev.terraform.overrideAttrs (oldAttrs: {
      version = "1.10.0-rc2";
      src = final.fetchFromGitHub {
        owner = "hashicorp";
        repo = "terraform";
        rev = "refs/tags/v${final.terraform.version}";
        hash = "sha256-V2iDXn/nkC6vPwF15+N4+ck/r83LXMbAU8E0rSZitSM=";
      };
      vendorHash = "sha256-UmPnOfjR6kYI0TMH2J54LzDeDGJKMkAC0xZk6xstIuk=";
    });
  };
}
