{ fetchgit }:

# A gist has neither tags nor releases, so there is no version stream for
# Renovate to follow and the revision is bumped by hand.
fetchgit {
  url = "https://gist.github.com/k16shikano/fd287c3133457c4fd8f5601d34aa817d.git";
  rev = "8f2d57610a73efc97d743c9b0b0ecb1002e09fa4";
  hash = "sha256-jo1DvsAVIAKzurutp+T66kctgaFEe+sVbY9bf7wlCLM=";
}
