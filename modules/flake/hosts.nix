# Tree-driven host loader. Each directory under hosts/<platform>/<name>/ becomes
# a system configuration: the platform segment selects the constructor and the
# host body sets nixpkgs.hostPlatform, so no host metadata lives outside its own
# directory -- the tree is the manifest. Every registry module of the matching
# class is injected into each host, inert until its option is set.
{
  config,
  inputs,
  lib,
  ...
}:
let
  hostsIn = dir: if builtins.pathExists dir then builtins.attrNames (builtins.readDir dir) else [ ];

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

  # nix-on-droid needs its own constructor, extraSpecialArgs, and an explicit
  # pkgs (the registry classes do not cover it). A single phone, so it is a
  # named branch rather than a readDir over hosts/android.
  nixOnDroidConfigurations.default = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "aarch64-linux";
      inherit (nixosConfigurations.kilimanjaro.config.nixpkgs) overlays;
      config.allowUnfree = true;
    };
    extraSpecialArgs = { inherit inputs; };
    modules = [ ../../hosts/android ];
  };
in
{
  flake = {
    inherit nixosConfigurations darwinConfigurations nixOnDroidConfigurations;
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
