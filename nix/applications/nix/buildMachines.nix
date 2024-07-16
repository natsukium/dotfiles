{ config, ... }:
let
  # hydra doesn't support ssh-ng protocol
  # https://github.com/NixOS/hydra/issues/688
  protocol = if (config.services ? hydra && config.services.hydra.enable) then "ssh" else "ssh-ng";
in
{
  nix = {
    distributedBuilds = true;

    extraOptions = ''
      builders-use-substitutes = true
    '';

    buildMachines = [
      {
        hostName = "kilimanjaro";
        systems = [
          "x86_64-linux"
          "i686-linux"
        ];
        sshUser = "natsukium";
        inherit protocol;
        maxJobs = 4;
        speedFactor = 1;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
        mandatoryFeatures = [ ];
      }
      {
        hostName = "serengeti";
        system = "aarch64-linux";
        sshUser = "natsukium";
        inherit protocol;
        maxJobs = 2;
        speedFactor = 1;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
        mandatoryFeatures = [ ];
      }
      {
        hostName = "mikumi";
        systems = [
          "aarch64-darwin"
          "x86_64-darwin"
        ];
        sshUser = "natsukium";
        inherit protocol;
        maxJobs = 4;
        speedFactor = 1;
        supportedFeatures = [
          "apple-virt"
          "benchmark"
          "big-parallel"
          "nixos-test"
        ];
        mandatoryFeatures = [ ];
      }
    ];
  };
}
