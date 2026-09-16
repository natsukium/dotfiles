{ fetchFromGitHub }:

let
  # renovate: datasource=github-releases depName=marimo-team/marimo-pair extractVersion=^v(?<version>.+)$
  version = "0.0.20";
in
fetchFromGitHub {
  owner = "marimo-team";
  repo = "marimo-pair";
  tag = "v${version}";
  hash = "sha256-8RvczH4eCr3eMgfy/NstKUmxDVJ7ad0Xp+l/l9W0r4U=";
}
