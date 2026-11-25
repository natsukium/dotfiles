{ fetchFromGitHub }:

let
  # renovate: datasource=github-releases depName=marimo-team/marimo-pair extractVersion=^v(?<version>.+)$
  version = "0.1.0";
in
fetchFromGitHub {
  owner = "marimo-team";
  repo = "marimo-pair";
  tag = "v${version}";
  hash = "sha256-cEmkL7EoAj5sB7Dediyv8nJH6jtWd+2AtCqZNzSrquY=";
}
