{
  inputs,
  pkgs,
  specialArgs,
  ...
}:
let
  inherit (pkgs) lib stdenv;
  inherit (specialArgs) username;
in
{
  imports = [
    ../../modules/darwin
    ../common.nix
    inputs.comin.darwinModules.comin
    inputs.sops-nix.darwinModules.sops
  ];

  sops = {
    defaultSopsFile = ../../secrets/default.yaml;
    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      generateKey = true;
    };
  };

  # uid and knownUsers are needed to set fish as the default shell
  # https://github.com/LnL7/nix-darwin/issues/1237#issuecomment-2562242340
  users = {
    users.${username} = {
      home = "/Users/${username}";
      uid = lib.mkDefault 501;
    };
    knownUsers = [ username ];
  };

  system.primaryUser = username;

  services.tailscale.enable = true;

  services.openssh.enable = true;

  my.services.spotlight.enableIndex = false;

  my.services.caffeinate = {
    enable = true;
    preventSleepOnCharge = true;
  };

  system.startup.chime = false;

  system.activationScripts.extraActivation.text = lib.optionalString stdenv.hostPlatform.isAarch64 ''
    if [ ! -d /usr/libexec/rosetta ]; then
      softwareupdate --install-rosetta --agree-to-license
    fi
  '';

  system.stateVersion = lib.mkDefault 4;

  # distributed builds fail with the following error
  # fish: Unknown command: nix-store
  # see the workaround
  # https://github.com/NixOS/nix/issues/7508#issuecomment-2597403478
  programs.fish.shellInit = ''
    if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish' && test -n "$SSH_CONNECTION"
      source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
    end
  '';

  services.prometheus.exporters.node.enable = true;

  # https://github.com/nix-darwin/nix-darwin/issues/1256
  users.users._prometheus-node-exporter.home = lib.mkForce "/private/var/lib/prometheus-node-exporter";

  environment.systemPackages = with pkgs; [
    commandLineToolsShim
  ];
}
