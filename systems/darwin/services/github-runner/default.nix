{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.github-runners =
    lib.genAttrs (map (n: "natsukium-macos-arm64-${toString n}") (lib.range 1 1))
      (name: {
        enable = true;
        package = pkgs.github-runner.overrideAttrs (_: {
          doCheck = false;
        });
        url = "https://github.com/attmcojp";
        tokenFile = config.sops.secrets.github-runner-token.path;
        replace = true;
        extraLabels = [ "bashauma-macos-arm64" ];
        extraPackages = with pkgs; [
          cachix
          curl
          docker
          # used by cachix/cachix-action's pushFilter
          findutils
          gnugrep
        ];
        extraEnvironment = {
          BASH_ENV = "/etc/profile.d/nix-profile.sh";
        };
      });

  sops.secrets.github-runner-token = {
    sopsFile = ./secrets.yaml;
    # readable by the linux-builder VM which mounts /run/secrets via 9P
    mode = "0444";
  };

  # nix-darwin places the _github-runner user's home under /var/lib/github-runners,
  # but /var on macOS is a symlink to /private/var which nix-darwin doesn't resolve
  users.users._github-runner.home = lib.mkForce "/private/var/lib/github-runners";
}
