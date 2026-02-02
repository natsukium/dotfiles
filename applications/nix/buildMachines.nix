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
      ++ lib.optional (config.networking.hostName != "mikumi" && config.networking.hostName != "work") {
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

  programs.ssh.knownHosts = {
    tarangire.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJJYgE/dmYLXYBrVnPicd0qsaUeqcBtXB8H9LHkJ2j4";
    kilimanjaro.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILhpfAalh6A5xDSE+HOdNE29ZgIjlP7tdlhHs82boSwp";
    serengeti.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDWwhfhDSZ+M2XDwP2MlC/zFfVpk3WjUxV/JWFgGzgNW";
    mikumi.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfWOWKBFuDV08g6xP9MMY78CERI02CNG+5dy8CXQmXs";
  };
}
