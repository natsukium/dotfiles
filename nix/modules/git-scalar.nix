{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.git.scalar;
in
{
  options.programs.git = {
    scalar = {
      enable = mkEnableOption "scalar";

      repo = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "~/NixOS/nixpkgs" ];
      };
    };
  };

  config = mkIf cfg.enable {
    programs.git.extraConfig = {
      scalar.repo = cfg.repo;
      core = {
        multipackindex = true;
        preloadindex = true;
        untrackedcache = true;
        autocrlf = false;
        safecrlf = false;
        fsmonitor = true;
      };
      am.keepcr = true;
      credential = {
        "https://dev.azure.com".usehttppath = true;
        validate = false;
      };
      gc.auto = 0;
      gui.gcwarning = false;
      index = {
        threads = true;
        version = 4;
      };
      merge = {
        stat = false;
        renames = true;
      };
      pack = {
        usebitmaps = false;
        usesparse = true;
      };
      receive.autogc = false;
      feature = {
        manyfiles = false;
        experimental = false;
      };
      fetch = {
        unpacklimit = 1;
        writecommitgraph = false;
        showforcedupdates = false;
      };
      status.aheadbehind = false;
      commitgraph.generationversion = 1;
      log.excludedecoration = "refs/prefetch/*";
      maintenance = {
        repo = cfg.repo;
        auto = false;
        strategy = "incremental";
      };
    };
  };
}
