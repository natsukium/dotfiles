{
  self,
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (builtins) attrValues pathExists;
  inherit (lib)
    filter
    last
    mapAttrs
    mkOption
    splitString
    types
    ;

  getDefaultPlatform =
    system: if (last (splitString "-" system)) == "linux" then "nixos" else "darwin";

  systemConfigurations =
    platform: hostname: attrs:
    if platform == "nixos" then
      { nixosConfigurations."${hostname}" = inputs.nixpkgs.lib.nixosSystem attrs; }
    else if platform == "darwin" then
      { darwinConfigurations."${hostname}" = inputs.darwin.lib.darwinSystem attrs; }
    else
      { nixOnDroidConfigurations.default = inputs.nix-on-droid.lib.nixOnDroidConfiguration attrs; };

  maybePath = path: if pathExists path then path else null;
in
{
  options.hosts = mkOption {
    default = { };
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options = {
            system = mkOption {
              default = "x86_64-linux";
              type = types.str;
            };
            platform = mkOption {
              default = getDefaultPlatform config.hosts.${name}.system;
              type = types.str;
            };
            modules = mkOption {
              default = [ ];
              type = types.listOf types.path;
            };
            username = mkOption {
              default = "natsukium";
              type = types.str;
            };
            specialArgs = mkOption {
              default = { };
              type = types.attrs;
            };
          };
        }
      )
    );
  };

  config = rec {
    flake = lib.foldAttrs (host: acc: host // acc) { } (
      attrValues (
        mapAttrs (
          name: cfg:
          systemConfigurations cfg.platform name (
            {
              modules =
                filter (x: x != null) [
                  (maybePath ./systems/${cfg.platform}/${name})
                  (maybePath ./homes/${cfg.platform}/${name})
                ]
                ++ lib.optionals (cfg.platform == "android") [
                  ./systems/nix-on-droid
                  ./homes/nix-on-droid
                ]
                ++ cfg.modules;
              "${if (cfg.platform == "android") then "extraS" else "s"}pecialArgs" = {
                inherit self inputs;
                inherit (cfg) username;
              } // cfg.specialArgs;
            }
            // lib.optionalAttrs (cfg.platform != "android") { inherit (cfg) system; }
            // lib.optionalAttrs (cfg.platform == "android") {
              pkgs = import inputs.nixpkgs {
                inherit (cfg) system;
                inherit (inputs.self.outputs.nixosConfigurations.kilimanjaro.config.nixpkgs) overlays;
              };
            }
          )
        ) config.hosts
      )
    );
    perSystem =
      {
        lib,
        system,
        ...
      }:
      {
        checks =
          let
            currentSystemConfigurations = lib.filterAttrs (k: v: v.pkgs.system == system) (
              flake.nixosConfigurations // flake.darwinConfigurations
            );
          in
          builtins.mapAttrs (k: v: v.config.system.build.toplevel) currentSystemConfigurations;
      };
  };
}
