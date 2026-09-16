# Renovate rewrites both the version and the hash below, and its regex manager
# only reads .nix files. Tangling this from configuration.org would put the
# annotation in a generated file, where a bump survives only until the next
# `make tangle` reverts it, so this file is written by hand.
{ fetchFromGitHub }:
let
  # renovate: datasource=github-releases depName=reizumii/parfait extractVersion=^v(?<version>.+)$
  version = "0.22";
in
fetchFromGitHub {
  owner = "reizumii";
  repo = "parfait";
  tag = "v${version}";
  hash = "sha256-N5+tznak3IZJAKXlim41zOJQrsoowC7Zv9N2zBnBgI4=";
}
