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

  services.tailscale.enable = true;

  services.openssh.enable = true;

  services.nix-daemon.enable = true;

  nixpkgs.config.allowUnfree = true;

  my.services.spotlight.enableIndex = false;

  my.services.caffeinate = {
    enable = true;
    preventSleepOnCharge = true;
  };

  system.startup.chime = false;

  system.activationScripts.extraActivation.text = lib.optionalString stdenv.hostPlatform.isAarch64 ''
    softwareupdate --install-rosetta --agree-to-license
  '';

  system.stateVersion = 5;
}
