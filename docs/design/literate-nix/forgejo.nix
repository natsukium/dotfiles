/*
  !
  # Forgejo

  I self-host [Forgejo](https://forgejo.org/) on manyara as my personal forge at
  `git.natsukium.com`. This feature carries the NixOS module that runs the
  instance and the home-manager module that routes git's ssh traffic to it.
*/
{ ... }:
{
  /**
    ## Instance

    Registration is closed since I am the only human user. Forgejo has no
    declarative way to define users, so my admin account and the renovate bot's
    are created at service start instead.
  */
  flake.modules.nixos.forgejo =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.forgejo;
    in
    {
      options.my.services.forgejo.enable = lib.mkEnableOption "my forgejo instance";

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            services.forgejo = {
              enable = true;
              package = pkgs.forgejo;
              database.type = "postgres";
              settings = {
                service.DISABLE_REGISTRATION = true;
                server = {
                  HTTP_PORT = 3010;
                  DOMAIN = "git.natsukium.com";
                  ROOT_URL = "https://git.natsukium.com/";
                };
                actions = {
                  ENABLED = true;
                  DEFAULT_ACTIONS_URL = "github";
                };
              };
            };

            systemd.services.forgejo.preStart = ''
              ${lib.getExe config.services.forgejo.package} admin user create \
                --username natsukium \
                --email "tomoya.otabi@gmail.com" \
                --password "$(tr -d '\n' < ${config.sops.secrets.forgejo-admin-password.path})" || true

              ${lib.getExe config.services.forgejo.package} admin user create \
                --username renovate \
                --email "renovate@natsukium.com" \
                --password "$(tr -d '\n' < ${config.sops.secrets.forgejo-renovate-password.path})" \
                --must-change-password=false || true
            '';

            sops.secrets.forgejo-admin-password = {
              sopsFile = ./secrets.yaml;
              owner = "forgejo";
            };

            sops.secrets.forgejo-renovate-password = {
              sopsFile = ./secrets.yaml;
              owner = "forgejo";
            };

            my.services.cloudflared-tunnel.ingress.${config.services.forgejo.settings.server.DOMAIN} =
              let
                inherit (config.services.forgejo.settings.server) HTTP_ADDR HTTP_PORT;
              in
              {
                service = "http://${toString HTTP_ADDR}:${toString HTTP_PORT}";
              };
          }

          /**
            ### SSH Port

            Tailscale runs with [`--ssh`](../tailscale.nix), so on the tailnet
            tailscaled answers port 22 itself and hands out a plain shell as
            `forgejo`. That bypasses the `command="forgejo serv"` restriction git
            depends on, so sshd moves to 2022. `SSH_PORT` is pinned to 22 anyway:
            forgejo only uses it to render clone URLs, and any other value turns
            them into full `ssh://` URIs. The ssh route on the client carries the
            real port.
          */
          {
            services.openssh.ports = [ 2022 ];
            services.forgejo.settings.server.SSH_PORT = 22;
          }

          /**
            ### Instance Signing

            Forgejo authors the commit itself when I merge a pull request or edit
            a file in the web UI, so those commits carry no signature. An instance
            key signs them, in the same SSH format as
            [my own commits](../git/git.nix).
          */
          {
            sops.secrets.forgejo-signing-key = {
              sopsFile = ./secrets.yaml;
              owner = "forgejo";
              path = "/var/lib/forgejo-signing/key";
            };

            systemd.tmpfiles.settings."10-forgejo-signing" = {
              "/var/lib/forgejo-signing".d = {
                user = "forgejo";
                group = "forgejo";
                mode = "0750";
              };
              "${config.sops.secrets.forgejo-signing-key.path}.pub"."L+".argument = toString (
                pkgs.writeText "forgejo-signing-key.pub" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAWHoqNuRjeO1o4x6pdrF3ZCZRluh80HWVP6X8j4k8pn forgejo@natsukium.com\n"
              );
            };

            services.forgejo.settings."repository.signing" = {
              FORMAT = "ssh";
              SIGNING_KEY = "${config.sops.secrets.forgejo-signing-key.path}.pub";
              SIGNING_NAME = "Forgejo";
              SIGNING_EMAIL = "forgejo@natsukium.com";
              MERGES = "always";
              CRUD_ACTIONS = "always";
            };

            systemd.services.forgejo.path = [ pkgs.openssh ];
          }

          /**
            ### Backup

            The repositories under `stateDir` are only half the instance: issues,
            users and access tokens live in postgres, and restoring one without
            the other leaves a Forgejo that cannot serve any of it. Upstream's
            `forgejo dump` is not an alternative: it warns that its own SQL dump
            has long-standing re-import bugs, and its zip would arrive as a fresh
            opaque blob every time, leaving restic nothing to deduplicate against
            yesterday's.
          */
          {
            services.postgresqlBackup = {
              enable = true;
              databases = [ config.services.forgejo.database.name ];
            };

            my.services.restic.backups.forgejo.paths = [
              config.services.forgejo.stateDir
              "${config.services.postgresqlBackup.location}/${config.services.forgejo.database.name}.sql.gz"
            ];
          }
        ]
      );
    };

  /**
    ## Client Settings

    What every machine of mine needs to talk to the instance: where ssh goes,
    and which remotes take that route.
  */
  flake.modules.homeManager.forgejo =
    { config, lib, ... }:
    {
      options.my.programs.forgejo.enable = lib.mkEnableOption "the ssh route to my forge";

      config = lib.mkIf config.my.programs.forgejo.enable {
        /**
          ### SSH Route

          `git.natsukium.com` resolves publicly to the cloudflared tunnel, which
          carries HTTP only, so ssh needs another path. Every machine of mine
          reaches manyara over tailscale, so this block points the public name at
          the tailnet one. It lands in `~/.ssh/config` through the
          [SSH Client](../ssh.nix) module, which owns the file.
        */
        programs.ssh.settings."git.natsukium.com" = {
          HostName = "manyara.tail4108.ts.net";
          Port = 2022;
        };

        /**
          ### Push URLs

          Remotes cloned over https would push over https as well. This rewrite
          routes every push to the forge over ssh instead, leaving fetch on the
          tunnel.
        */
        programs.git.settings.url."forgejo@git.natsukium.com:".pushInsteadOf = "https://git.natsukium.com/";
      };
    };
}
