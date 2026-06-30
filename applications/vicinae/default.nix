{ inputs, pkgs, ... }:
{
  # rbw-backed credential picker, the Vicinae equivalent of the rofi-rbw setup.
  # Built from the local source with the launcher fork's mkVicinaeExtension so it
  # is installed declaratively alongside the upstream extensions.
  programs.vicinae.extensions = [
    (inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkVicinaeExtension {
      pname = "vicinae-extension-rbw";
      version = "0";
      src = ./rbw;
      # Vicinae's launchd/systemd unit has a minimal PATH, so spawning bare `rbw`
      # fails with ENOENT. Bake in rbw's absolute bin/ (which also holds
      # rbw-agent, found via PATH) so the picker works without extra setup.
      postPatch = ''
        substituteInPlace src/vault.ts \
          --replace-fail '@rbwBinDir@' '${pkgs.rbw}/bin'
      '';
    })
  ];
}
