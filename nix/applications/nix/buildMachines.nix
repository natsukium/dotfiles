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
        protocol = "ssh-ng";
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
        protocol = "ssh-ng";
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
        protocol = "ssh-ng";
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
