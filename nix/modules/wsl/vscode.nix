# This module's reference, https://discourse.nixos.org/t/vscode-remote-wsl-extension-works-on-nixos-without-patching-thanks-to-nix-ld/14615
{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.vscode-wsl;
  ldEnv = {
    NIX_LD_LIBRARY_PATH = with pkgs; makeLibraryPath [ stdenv.cc.cc ];
    NIX_LD = removeSuffix "\n" (builtins.readFile "${pkgs.stdenv.cc}/nix-support/dynamic-linker");
  };
  ldExports = mapAttrsToList (name: value: "export ${name}=${value}") ldEnv;
  joinedLdExports = concatStringsSep "\n" ldExports;
in
{
  options.vscode-wsl = {
    enable = mkEnableOption "enable vscode-remote-wsl";
    user = mkOption {
      type = types.str;
      description = "The name of user you want to configure for using VSCode's Remote WSL extension.";
      default = config.wsl.defaultUser;
    };
  };
  config = mkIf cfg.enable {
    environment.variables = ldEnv;
    home-manager.users.${cfg.user}.home.file.".vscode-server/server-env-setup".text = joinedLdExports;
  };
}
