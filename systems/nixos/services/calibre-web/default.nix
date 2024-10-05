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

  my.services.calibre-web = {
    adminPasswordFile = config.sops.secrets.calibre-web-admin-password.path;
  };

  sops.secrets.calibre-web-admin-password = {
    sopsFile = ./secrets.yaml;
  };
}
