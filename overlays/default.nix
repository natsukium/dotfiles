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

  temporary-fix =
    final: prev:
    {
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
