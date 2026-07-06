{ inputs, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    config = {
      imports = [ ../common.nix ] ++ builtins.attrValues inputs.self.modules.homeManager;
    };
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
      # disabledModules not working
      # https://github.com/nix-community/home-manager/issues/1792
      modulesPath = "${inputs.home-manager}/modules";
    };
  };
}
