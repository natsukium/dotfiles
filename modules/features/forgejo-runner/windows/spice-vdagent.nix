{ fetchurl }:

let
  # renovate: datasource=custom.spice-vdagent depName=spice-vdagent extractVersion=^vdagent-win-(?<version>.+)/$
  version = "0.10.0";
in
fetchurl {
  url = "https://www.spice-space.org/download/windows/vdagent/vdagent-win-${version}/spice-vdagent-x64-${version}.msi";
  hash = "sha256-d2KUNXBbwn3X0lJenSCE9y26tf2/MQ6BL5EzL+GNAOs=";
}
