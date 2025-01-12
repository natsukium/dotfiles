{ config, pkgs, ... }:
{
  services.hydra = {
    enable = true;
    hydraURL = "http://127.0.0.1";
    port = 3000;
    notificationSender = "";
    buildMachinesFiles = [
      "/etc/nix/machines"
      "/var/lib/hydra/provisioner/machines"
    ];
    useSubstitutes = true;
  };

  services.tsnsrv.services.hydra = {
    ephemeral = true;
    authKeyPath = config.sops.secrets.tailscale-authkey.path;
    toURL = config.services.hydra.hydraURL;
  };

  sops.secrets = {
    hydra-admin-password = {
      sopsFile = ./secrets.yaml;
      owner = "hydra";
    };
    hydra-users = {
      sopsFile = ./secrets.yaml;
      owner = "hydra";
    };
  };

  # delete build logs older than 30 days
  systemd.services.hydra-delete-old-logs = {
    startAt = "Sun 05:45";
    serviceConfig.ExecStart = "${pkgs.findutils}/bin/find /var/lib/hydra/build-logs -type f -mtime +30 -delete";
  };

  # Create user accounts
  # format: user;role;password-hash;email-address;full-name
  # Password hash is computed by applying argon2id to the password.
  # example
  # $ nix shell nixpkgs#libargon2
  # $ tr -d \\n | argon2 "$(LC_ALL=C tr -dc '[:alnum:]' < /dev/urandom | head -c16)" -id -t 3 -k 262144 -p 1 -l 16 -e
  # foobar
  # Ctrl^D
  # $argon2id$v=19$m=262144,t=3,p=1$NFU1QXJRNnc4V1BhQ0NJQg$6GHqjqv5cNDDwZqrqUD0zQ  # spellchecker:disable-line
  systemd.services.hydra-post-init = {
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "60";
    };
    wantedBy = [ "multi-user.target" ];
    after = [ "hydra-server.service" ];
    requires = [ "hydra-server.service" ];
    environment = {
      inherit (config.systemd.services.hydra-init.environment) HYDRA_DBI;
    };
    path = [
      config.services.hydra.package
      pkgs.netcat
    ];
    script = ''
      set -e
      while IFS=';' read -r user role passwordhash email fullname; do
        opts=("$user" "--role" "$role" "--password-hash" "$passwordhash")
        if [[ -n "$email" ]]; then
          opts+=("--email-address" "$email")
        fi
        if [[ -n "$fullname" ]]; then
          opts+=("--full-name" "$fullname")
        fi
        hydra-create-user "''${opts[@]}"
      done < ${config.sops.secrets.hydra-users.path}

      while ! nc -z localhost ${toString config.services.hydra.port}; do
        sleep 1
      done

      export HYDRA_ADMIN_PASSWORD=$(cat ${config.sops.secrets.hydra-admin-password.path})
      export URL=http://localhost:${toString config.services.hydra.port}
    '';
  };

  ext.hydra.localBuilder.enable = true;
}
