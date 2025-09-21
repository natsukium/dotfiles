{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../../modules/profiles/nixos/base.nix
    ../../../modules/profiles/nixos/nvidia.nix
    ../../shared/hercules-ci/agent.nix
    ../common.nix
    ../desktop.nix
    ../services/gitea-actions-runner
    ../services/hydra
    ../services/llm
    ./hardware-configuration.nix
  ];

  inherit
    (pkgs.callPackage ./disko-config.nix {
      disks = [ "/dev/disk/by-id/nvme-MS950G75PCIe4_2048G_30107347368" ];
    })
    disko
    ;

  ext.security.secureboot.enable = true;

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_xanmod_latest;

    # it is required to run `nixos-rebuild switch --target ${aarch64-linux machines}`
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  networking = {
    hostName = "kilimanjaro";
    wireless = {
      enable = true;
      secretsFile = config.sops.secrets.wifi.path;
      networks."82128927-5G".pskRaw = "ext:home";
    };
  };

  fileSystems."/persistent".neededForBoot = true;

  sops.secrets.wifi = { };

  nix.settings = {
    max-jobs = 4;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  dualboot.enable = true;

  programs.nix-ld.enable = true;

  services.pipewire.wireplumber.extraConfig = {
    "51-alsa-default" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {
              "node.name" = "alsa_output.pci-0000_01_00.1.hdmi-stereo";
            }
          ];
          actions = {
            update-props = {
              "priority.driver" = 1000;
              "priority.session" = 1000;
            };
          };
        }
      ];
    };
    "99-ephemeral" = {
      "wireplumber.settings" = {
        "node.restore-default-targets" = false;
      };
    };
  };
}
