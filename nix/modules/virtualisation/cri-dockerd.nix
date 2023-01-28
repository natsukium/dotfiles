{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.virtualisation.cri-dockerd;
  cri-dockerd = (import ../../pkgs/cri-dockerd/default.nix) pkgs;
in
  with lib; {
    options.virtualisation.cri-dockerd = with types; {
      enable = mkEnableOption "cri-dockerd container runtime";
    };
    config = mkIf cfg.enable {
      environment.systemPackages = [cri-dockerd];

      systemd.services.cri-docker = {
        description = "CRI Interface for Docker Application Container Engine";
        wantedBy = ["multi-user.target"];
        after = ["network.target" "cri-docker.socket"];
        requires = ["cri-docker.socket"];
        serviceConfig = {
          Type = "notify";
          ExecStart = [
            ""
            ''
              ${cri-dockerd}/bin/cri-dockerd \
                --container-runtime-endpoint fd://
            ''
          ];
          ExecReload = [
            ""
            "${pkgs.procps}/bin/kill -s HUP $MAINPID"
          ];
          TimeoutSec = 0;
          RestartSec = 2;
          Restart = "always";
          StartLimitBurst = 3;
          LimitNOFILE = "infinity";
          LimitNPROC = "infinity";
          LimitCORE = "infinity";
          TasksMax = "infinity";
          Delegate = "yes";
          KillMode = "process";
        };
        path = with pkgs; [cri-dockerd iptables cni-plugins cni-plugin-flannel conntrack-tools util-linux];
      };
      systemd.sockets.cri-docker = {
        description = "CRI Docker Socket for the API";
        wantedBy = ["sockets.target"];
        partOf = ["cri-docker.service"];
        socketConfig = {
          ListenStream = "%t/cri-dockerd.sock";
          SocketMode = "0660";
          SocketUser = "root";
          SocketGroup = "docker";
        };
      };
    };
  }
