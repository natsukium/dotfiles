{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.services.home-assistant) configDir;
  recorderName = "home-assistant_v2.db";
  recorderStage = "/var/backup/hass";

  # Custom components must be built against home-assistant's own Python interpreter
  # so that propagated Python deps line up with the rest of the HA wrapper.
  homeAssistantPyPkgs = config.services.home-assistant.package.python3Packages;
  pypetkitapi = homeAssistantPyPkgs.callPackage ./pypetkitapi.nix { };
  sdp-transform = homeAssistantPyPkgs.callPackage ./sdp-transform.nix { };
  petkit = homeAssistantPyPkgs.callPackage ./petkit.nix {
    inherit (pkgs) buildHomeAssistantComponent;
    inherit pypetkitapi sdp-transform;
  };
in
{
  imports = [
    ./metrics.nix
    ./port.nix
  ];

  services.home-assistant = {
    enable = true;
    extraComponents = [
      "default_config"
      "met"
      "switchbot"
      "switchbot_cloud"
      "ecovacs"
      "prometheus"
    ];
    customComponents = [ petkit ];
    config = {
      homeassistant = {
        name = "Home";
        unit_system = "metric";
      };
      prometheus = { };
      recorder.purge_keep_days = 14;
      history = { };
      logbook = { };
    };
  };

  services.caddy.virtualHosts."http://ha.home.natsukium.com".extraConfig = ''
    reverse_proxy localhost:${toString config.my.services.home-assistant.port}
  '';

  # I snapshot the configuration directory rather than the backup integration,
  # which is the supported path but writes a securetar archive that lands whole
  # every night, so restic would store a full copy each run and retention would
  # be set in two places. What it costs me is the restore button in onboarding.
  #
  # Recorder holds its database open in WAL mode for as long as Home Assistant
  # runs, so the files on disk are a torn copy. sqlite's backup API produces a
  # consistent one without stopping the service, and it runs as hass so the -wal
  # and -shm files it touches keep their owner -- root creating them would lock
  # Home Assistant out of its own database on the next restart. Upstream's
  # backup does not go this far: it tars the open database together with its
  # -wal and leaves the replay to sqlite on restore.
  my.services.restic.backups.home-assistant = {
    paths = [
      configDir
      "${recorderStage}/${recorderName}"
    ];
    # Upstream's own EXCLUDE_FROM_BACKUP list, trimmed to what exists on a
    # Linux server, plus the live database that the staged copy replaces.
    exclude = [
      "${configDir}/${recorderName}*"
      "${configDir}/tts"
      "${configDir}/.cache"
      "${configDir}/backups"
      "${configDir}/tmp_backups"
      "${configDir}/*.log*"
      "**/__pycache__"
    ];
    prepare = ''
      # Handed a path that does not exist, sqlite3 creates the database, and
      # .backup then writes a valid empty copy and exits zero -- a backup that
      # looks like it worked. Refuse instead.
      test -f ${configDir}/${recorderName}
      ${pkgs.coreutils}/bin/install -d -m 0700 -o hass -g hass ${recorderStage}
      ${pkgs.util-linux}/bin/runuser -u hass -- \
        ${lib.getExe pkgs.sqlite} ${configDir}/${recorderName} \
        ".backup '${recorderStage}/${recorderName}'"
    '';
  };

  # The SwitchBot BLE integration scans for devices through BlueZ on the host.
  hardware.bluetooth.enable = true;
}
