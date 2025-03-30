{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.colima;
  yamlFormat = pkgs.formats.yaml { };
in
{
  options.programs.colima = {
    enable = mkEnableOption "";
    enableXDG = mkOption {
      type = types.bool;
      default = !(pkgs.stdenv.isDarwin && pkgs.stdenv.isx86_64);
      description = "";
    };
    package = mkOption {
      type = types.package;
      default = pkgs.colima;
      description = "Package providing <command>colima<command>.";
    };
    enableDocker = mkOption {
      type = types.bool;
      default = true;
      description = "Container runtime to be used (docker, containerd).";
    };
    packageDocker = mkOption {
      type = types.package;
      default = pkgs.docker-client;
      description = "Package providing <command>docker client<command>.";
    };
    packageDockerBuildX = mkOption {
      type = types.package;
      default = pkgs.docker-buildx;
      description = "Package providing <command>docker buildx<command>.";
    };
    enableKubernetes = mkOption {
      type = types.bool;
      default = false;
      description = "Enable kubernetes.";
    };
    packageKubectl = mkOption {
      default = pkgs.kubectl;
      type = types.package;
      description = "Package providing <command>kubectl<command>.";
    };
    vmType = mkOption {
      type = types.str;
      default = if (pkgs.stdenv.isDarwin && pkgs.stdenv.isAarch64) then "vz" else "qemu";
      description = "Virtual Machine type (qemu, vz)";
    };
    mountType = mkOption {
      type = types.str;
      default = if (cfg.vmType == "vz") then "virtiofs" else "9p";
      description = "Volume mount driver for the virtual machine (virtiofs, 9p, sshfs).";
    };
    enableRosetta = mkOption {
      type = types.bool;
      default = pkgs.stdenv.isDarwin && pkgs.stdenv.isAarch64;
      description = "Utilise rosetta for amd64 emulation (requires m1 mac and vmType `vz`)";
    };
    # TODO: enable profiles
    settings = mkOption {
      type = yamlFormat.type;
      default = { };
    };
    template = mkOption {
      type = yamlFormat.type;
      default = {
        cpu = 2;
        disk = 60;
        memory = 2;
        arch = "host";
        runtime = "docker";
        hostname = null;
        kubernetes = {
          enabled = false;
          version = "v1.24.3+k3s1";
          k3sArgs = [ "--disable=traefik" ];
        };
        autoActivate = true;
        network = {
          address = false;
          dns = [ ];
          dnsHosts = { };
        };
        forwardAgent = false;
        docker = { };
        vmType = "qemu";
        rosetta = false;
        mountType = "9p";
        mountInotify = false;
        cpuType = "host";
        provision = [ ];
        sshConfig = true;
        mounts = [ ];
        env = { };
      };
      description = ''
        Default configuration written to
        <filename>$XDG_CONFIG_HOME/colima/<profile>/colima.yaml</filename>.
        </para><para>
        See `colima template` for the configuration.
      '';
    };
  };
  config =
    let
      settings =
        cfg.template
        // cfg.settings
        // {
          inherit (cfg) vmType mountType;
          rosetta = cfg.enableRosetta;
          runtime = if cfg.enableDocker then "docker" else "containerd";
          kubernetes.enabled = cfg.enableKubernetes;
        };
    in
    mkIf cfg.enable (mkMerge [
      {
        home.packages =
          [ cfg.package ]
          ++ optionals cfg.enableDocker [
            cfg.packageDocker
            cfg.packageDockerBuildX
          ]
          ++ optionals cfg.enableKubernetes [ cfg.packageKubectl ];

        # colima needs writable settings file
        # https://github.com/nix-community/home-manager/issues/1800
        home.activation.afterWriteBoundary = {
          after = [ "writeBoundary" ];
          before = [ ];
          data = ''
            colimaDir=${
              if cfg.enableXDG then "${config.xdg.configHome}/colima" else "${config.home.homeDirectory}/.colima"
            }/default
            rm -rf $colimaDir/colima.yaml
            mkdir -p $colimaDir
            cat \
              ${yamlFormat.generate "colima.yaml" settings} \
              > $colimaDir/colima.yaml
          '';
        };

        launchd.agents.colima = {
          enable = true;
          config = {
            ProgramArguments = [ "${lib.getExe cfg.package}" ];
            RunAtLoad = true;
          };
        };
      }
    ]);
}
