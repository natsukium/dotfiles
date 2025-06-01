{
  inputs,
  config,
  lib,
  ...
}:
let
  # hydra doesn't support ssh-ng protocol
  # https://github.com/NixOS/hydra/issues/688
  protocol = if (config.services ? hydra && config.services.hydra.enable) then "ssh" else "ssh-ng";
  inherit (inputs.self.outputs.nixosConfigurations) kilimanjaro serengeti tarangire;
  inherit (inputs.self.outputs.darwinConfigurations) mikumi;
in
{
  nix = {
    distributedBuilds = true;

    extraOptions = ''
      builders-use-substitutes = true
    '';

    buildMachines =
      [ ]
      ++ lib.optional (config.networking.hostName != "tarangire") {
        inherit (tarangire.config.networking) hostName;
        systems = [
          "x86_64-linux"
          "i686-linux"
        ];
        sshUser = "natsukium";
        inherit protocol;
        maxJobs = tarangire.config.nix.settings.max-jobs;
        speedFactor = 1;
        supportedFeatures = tarangire.config.nix.settings.system-features;
        mandatoryFeatures = [ ];
      }
      ++ lib.optional (config.networking.hostName != "kilimanjaro") {
        inherit (kilimanjaro.config.networking) hostName;
        systems = [
          "x86_64-linux"
          "i686-linux"
        ];
        sshUser = "natsukium";
        inherit protocol;
        maxJobs = kilimanjaro.config.nix.settings.max-jobs;
        speedFactor = 1;
        supportedFeatures = kilimanjaro.config.nix.settings.system-features;
        mandatoryFeatures = [ ];
      }
      ++ lib.optional (config.networking.hostName != "serengeti") {
        inherit (serengeti.config.networking) hostName;
        system = "aarch64-linux";
        sshUser = "natsukium";
        inherit protocol;
        maxJobs = serengeti.config.nix.settings.max-jobs;
        speedFactor = 1;
        supportedFeatures = serengeti.config.nix.settings.system-features;
        mandatoryFeatures = [ ];
      }
      ++ lib.optional (config.networking.hostName != "mikumi") {
        inherit (mikumi.config.networking) hostName;
        systems = [
          "aarch64-darwin"
          "x86_64-darwin"
        ];
        sshUser = "natsukium";
        inherit protocol;
        maxJobs = mikumi.config.nix.settings.max-jobs;
        speedFactor = 1;
        supportedFeatures = [
          "apple-virt"
          "benchmark"
          "big-parallel"
          "nixos-test"
        ];
        mandatoryFeatures = [ ];
      };
  };
}
