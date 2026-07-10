{
  config,
  inputs,
  pkgs,
  ...
}:
let
  inherit (pkgs) lib stdenv;
  inherit (config.my) username;
in
{
  imports = [
    ../../modules/darwin
    ../common.nix
    inputs.comin.darwinModules.comin
    inputs.sops-nix.darwinModules.sops
  ];

  my.programs.felis.enable = true;
  my.programs.fish.enable = true;

  sops = {
    defaultSopsFile = ../../secrets/default.yaml;
    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      generateKey = true;
    };
  };

  users.users.${username}.home = "/Users/${username}";

  system.primaryUser = username;

  services.tailscale = {
    enable = true;
    overrideLocalDns = true;
  };

  services.openssh.enable = true;

  my.services.spotlight.enableIndex = false;

  my.services.caffeinate = {
    enable = true;
    preventSleepOnCharge = true;
  };

  my.services.newsyslog.enable = true;

  system.startup.chime = false;

  system.activationScripts.extraActivation.text = lib.optionalString stdenv.hostPlatform.isAarch64 ''
    if [ ! -d /usr/libexec/rosetta ]; then
      softwareupdate --install-rosetta --agree-to-license
    fi
  '';

  system.stateVersion = lib.mkDefault 4;

  services.prometheus.exporters.node.enable = true;

  # https://github.com/nix-darwin/nix-darwin/issues/1256
  users.users._prometheus-node-exporter.home = lib.mkForce "/private/var/lib/prometheus-node-exporter";

  environment.systemPackages = with pkgs; [
    commandLineToolsShim
  ];
}
