"""Tests for update_nix_hash, using the shapes this repository actually pins."""

import pytest

from update_nix_hash import Unsupported, rewrite, source, update

# A home-assistant component: the fetcher inherits `owner` from the derivation,
# takes the tag straight from `version`, and -- the trap -- the derivation also
# has an unrelated `domain` attribute.
COMPONENT = """
buildHomeAssistantComponent rec {
  owner = "Jezza34000";
  domain = "petkit";
  version = "1.25.0";

  src = fetchFromGitHub {
    inherit owner;
    repo = "homeassistant_petkit";
    tag = version;
    hash = "sha256-1YFE2s4MV37PNRdDg35zWgfNxdNny82pdheHa87Xsus=";
  };
}
"""

# A python package whose upstream prefixes its tags.
PREFIXED_TAG = """
buildPythonPackage (finalAttrs: {
  pname = "sdp-transform";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "skymaze";
    repo = "sdp-transform";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Sr1wCXRLg6GU3JvHSekoxr6vaeI/vAnvb2BI6tjpqEs=";
  };
})
"""

# A released file rather than a repository, with the version appearing twice.
PLAIN_URL = """
let
  version = "9.0.55";
in
pkgs.fetchurl {
  url = "https://github.com/retorquere/zotero-better-bibtex/releases/download/v${version}/zotero-better-bibtex-${version}.xpi";
  hash = "sha256-LZFOuxdMLFkOz/dBppA/GXkGW0J0DzAdk47Cy2wD5NY=";
}
"""

SELF_HOSTED_FORGE = """
buildGoModule {
  version = "0.3.1";

  src = fetchFromGitea {
    domain = "git.natsukium.com";
    owner = "natsukium";
    repo = "spoor";
    rev = "v${version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
}
"""


def test_tag_taken_from_version():
    assert source(COMPONENT) == (
        "https://github.com/Jezza34000/homeassistant_petkit/archive/1.25.0.tar.gz",
        True,
    )


def test_domain_outside_the_fetcher_is_not_a_host():
    """`domain = "petkit"` belongs to the component, not to a Gitea source."""
    url, _ = source(COMPONENT)
    assert url.startswith("https://github.com/")


def test_prefixed_tag_is_interpolated():
    assert source(PREFIXED_TAG) == (
        "https://github.com/skymaze/sdp-transform/archive/v1.1.0.tar.gz",
        True,
    )


def test_plain_url_resolves_every_interpolation_and_is_not_unpacked():
    assert source(PLAIN_URL) == (
        "https://github.com/retorquere/zotero-better-bibtex/releases/download/"
        "v9.0.55/zotero-better-bibtex-9.0.55.xpi",
        False,
    )


def test_self_hosted_forge_uses_its_domain():
    assert source(SELF_HOSTED_FORGE) == (
        "https://git.natsukium.com/natsukium/spoor/archive/v0.3.1.tar.gz",
        True,
    )


def test_missing_version_is_reported():
    with pytest.raises(Unsupported, match="version"):
        source('src = fetchFromGitHub {\n  owner = "a";\n  repo = "b";\n};\n')


def test_file_without_a_fetcher_is_reported():
    with pytest.raises(Unsupported, match="fetcher"):
        source('{\n  version = "1.0";\n}\n')


def test_rewrite_replaces_the_hash():
    rewritten = rewrite(PREFIXED_TAG, "sha256-new=")
    assert 'hash = "sha256-new=";' in rewritten
    assert "sha256-Sr1wCX" not in rewritten
    assert 'version = "1.1.0";' in rewritten


def test_rewrite_refuses_more_than_one_source():
    """Two sources in one file would both be clobbered by a single hash."""
    with pytest.raises(Unsupported, match="exactly one"):
        rewrite(PREFIXED_TAG + PLAIN_URL, "sha256-new=")


def test_update_writes_the_fetched_hash(tmp_path):
    path = tmp_path / "package.nix"
    path.write_text(PREFIXED_TAG.replace("1.1.0", "1.2.0"))

    fetched = []

    def fake_prefetch(url, unpack):
        fetched.append((url, unpack))
        return "sha256-refetched="

    update(path, fetch=fake_prefetch)

    assert fetched == [
        ("https://github.com/skymaze/sdp-transform/archive/v1.2.0.tar.gz", True)
    ]
    assert 'hash = "sha256-refetched=";' in path.read_text()
