# Host loader. Each directory under hosts/<platform>/<name>/ becomes a system
# configuration; the platform segment selects the constructor and the
# architecture is set via nixpkgs.hostPlatform inside the host body. No host
# metadata lives outside its own directory — the tree is the manifest.
#
# Every registry module of the matching class is injected into each host, inert
# until its option is set; Home Manager registry modules cross into the user
# evaluation through home-manager.sharedModules, wired by the home hosts
# themselves (see hosts/*/ with home-manager).
{
  config,
  inputs,
  lib,
  ...
}:
let
  hostsIn = dir: builtins.attrNames (builtins.readDir dir);

  mkHost =
    class: mkSystem: name:
    mkSystem {
      specialArgs = { inherit inputs; };
      modules = [
        (../../hosts + "/${class}/${name}")
      ]
      ++ builtins.attrValues config.flake.modules.${class};
    };

  nixosConfigurations = lib.genAttrs (hostsIn ../../hosts/nixos) (
    mkHost "nixos" inputs.nixpkgs.lib.nixosSystem
  );
  darwinConfigurations = lib.genAttrs (hostsIn ../../hosts/darwin) (
    mkHost "darwin" inputs.darwin.lib.darwinSystem
  );
in
{
  flake = {
    inherit nixosConfigurations darwinConfigurations;

    nixOnDroidConfigurations.default = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
      pkgs = import inputs.nixpkgs {
        system = "aarch64-linux";
        inherit (inputs.self.outputs.nixosConfigurations.kilimanjaro.config.nixpkgs) overlays;
        config.allowUnfree = true;
      };
      extraSpecialArgs = { inherit inputs; };
      modules = [ ../../hosts/android ];
    };
  };

  perSystem =
    { system, lib, ... }:
    {
      checks =
        let
          current = lib.filterAttrs (_: v: v.pkgs.stdenv.hostPlatform.system == system) (
            nixosConfigurations // darwinConfigurations
          );
        in
        builtins.mapAttrs (_: v: v.config.system.build.toplevel) current;
    };
}
