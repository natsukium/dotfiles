{
  name = "calibre-web";

  nodes.machine =
    { pkgs, ... }:
    {
      imports = [ ../../modules/nixos/calibre-web.nix ];

      services.calibre-web = {
        enable = true;
        options = {
          calibreLibrary = "/data/books";
        };
      };

      my.services.calibre-web = {
        adminPasswordFile = pkgs.runCommandNoCC "admin-password" { } ''
          echo "dummy-HDat1@WLJ&9AdSfc!MEH" > $out
        '';
      };
    };

  testScript = ''
    machine.wait_for_unit("calibre-web.service")

    # database should exist and be owned by calibre-web user
    machine.succeed("[ -f /data/books/metadata.db ]")
    machine.succeed("ls -l /data/books/metadata.db | grep \"calibre-web calibre-web\"")

    # admin password should be changed declaratively
    machine.wait_for_open_port(8083)
    machine.succeed("journalctl -u calibre-web-init-admin-password | grep \"Password for user 'admin' changed\"")
  '';
}
