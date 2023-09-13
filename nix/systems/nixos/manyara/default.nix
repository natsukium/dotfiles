{
  config,
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs) inputs username;
  inherit (inputs) tsnsrv;
in {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../services/tailscale.nix
    tsnsrv.nixosModules.default
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.${username} = {
    home = "/home/${username}";
    isNormalUser = true;
    initialPassword = "";
    extraGroups = ["wheel"];
  };

  networking = {
    hostName = "manyara";
  };

  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  environment.systemPackages = [pkgs.coreutils];

  services.tsnsrv = {
    enable = true;
    defaults.authKeyPath = ../../../../ts_authkey;
  };

  services.miniflux = {
    enable = true;
    adminCredentialsFile = ../miniflux;
    config = {
      PORT = "8080";
    };
  };

  services.tsnsrv.services.rss-reader = {
    ephemeral = true;
    toURL = "http://127.0.0.1:${config.services.miniflux.config.PORT}";
  };

  services.calibre-web = {
    enable = true;
    options.enableBookUploading = true;
  };

  services.tsnsrv.services.book = {
    ephemeral = true;
    toURL = "http://127.0.0.1:${builtins.toString config.services.calibre-web.listen.port}";
  };

  services.grafana = {
    enable = true;
    settings.server = {
      domain = "natsukium.com";
      http_port = 2342;
      http_addr = "0.0.0.0";
    };
  };

  services.tsnsrv.services.dashboard = {
    ephemeral = true;
    toURL = "http://127.0.0.1:${builtins.toString config.services.grafana.settings.server.http_port}";
  };

  # services.prometheus = {
  #   enable = true;
  #   port = 9001;
  #   exporters = {
  #     node = {
  #       enable = true;
  #       enabledCollectors = ["systemd"];
  #       port = 9002;
  #     };
  #   };
  #   scrapeConfigs = [
  #     {
  #       job_name = "manyara";
  #       static_configs = [{
  #         targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
  #       }];
  #     }
  #   ];
  # };
}
