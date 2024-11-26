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

  users.users.${username}.home = "/Users/${username}";

  services.tailscale.enable = true;

  services.nix-daemon.enable = true;

  nixpkgs.config.allowUnfree = true;

  # need to run `chsh -s /run/current-system/sw/bin/fish` manually
  # https://github.com/LnL7/nix-darwin/issues/811
  system.activationScripts.extraActivation.text =
    ''
      chsh -s /run/current-system/sw/bin/fish
    ''
    + lib.optionalString stdenv.isAarch64 ''
      softwareupdate --install-rosetta --agree-to-license
    '';

  system.stateVersion = 5;
}
