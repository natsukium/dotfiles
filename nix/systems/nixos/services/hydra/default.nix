{config, ...}: {
  services.hydra = {
    enable = true;
    hydraURL = "http://127.0.0.1:3000";
    notificationSender = "";
    buildMachinesFiles = ["/var/lib/hydra/provisioner/machines"];
    useSubstitutes = true;
  };

  services.tsnsrv.services.hydra = {
    ephemeral = true;
    authKeyPath = "/run/credentials/tsnsrv-hydra.service/credentials";
    toURL = config.services.hydra.hydraURL;
  };

  systemd.services.tsnsrv-hydra.serviceConfig.LoadCredential = "credentials:${config.sops.secrets.tailscale-authkey.path}";
}
