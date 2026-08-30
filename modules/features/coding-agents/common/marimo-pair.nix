{ fetchFromGitHub }:

let
  # renovate: datasource=github-releases depName=marimo-team/marimo-pair extractVersion=^v(?<version>.+)$
  version = "0.0.19";
in
fetchFromGitHub {
  owner = "marimo-team";
  repo = "marimo-pair";
  tag = "v${version}";
  hash = "sha256-4imWa2exUDg7nQmKooi7JFvozCyLVXMtW3KgB5xcCfI=";
}
