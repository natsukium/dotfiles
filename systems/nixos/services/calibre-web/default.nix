{ config, ... }:
{
  services.calibre-web = {
    enable = true;
    listen.ip = "0.0.0.0";
    options = {
      enableBookUploading = true;
      calibreLibrary = "/data/books";
    };
  };

  # calibre-web shares /data/books with syncthing (group member via calibre-web group).
  # default umask 0022 strips group write on new book dirs, leaving syncthing unable to
  # unlink files when a delete propagates from a peer — match syncthing's UMask=0002.
  systemd.services.calibre-web.serviceConfig.UMask = "0002";

  my.services.calibre-web = {
    adminPasswordFile = config.sops.secrets.calibre-web-admin-password.path;
  };

  sops.secrets.calibre-web-admin-password = {
    sopsFile = ./secrets.yaml;
  };
}
