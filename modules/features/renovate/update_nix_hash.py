#!/usr/bin/env python3
"""Recompute the hash of a Nix source whose version was just bumped.

Renovate's regex manager rewrites a `version` string and nothing else, which
leaves the `hash` beside it stale and the pull request unbuildable. Everything
needed to fetch the source again is still in the file, so this reads it back and
only has to be told which file to look at.
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

# The fetcher call, from its opening brace to the `};` that closes it. Attribute
# names are not unique within a file -- `domain` is a Gitea source's host but
# also a home-assistant component's identifier -- so I scope lookups to this.
FETCHER = re.compile(r"fetch[A-Za-z]+\s*\{(?P<body>.*?)^\s*\}", re.DOTALL | re.MULTILINE)

HASH = re.compile(r'hash = "sha256-[^"]*";')

INTERPOLATION = re.compile(r"\$\{[^}]*\}")


class Unsupported(Exception):
    """The file does not pin a source this can update."""


def attribute(text: str, name: str) -> str | None:
    """The right-hand side of `name`, verbatim, so quotes survive."""
    match = re.search(rf"^\s*{re.escape(name)} = (.*);\s*$", text, re.MULTILINE)
    return match.group(1) if match else None


def literal(text: str, name: str) -> str | None:
    """The value of `name` when it is a plain string."""
    value = attribute(text, name)
    if value is None or not (value.startswith('"') and value.endswith('"')):
        return None
    return value[1:-1]


def resolve(expr: str, version: str) -> str:
    """Evaluate an attribute that is written in terms of the version.

    Either a bare reference to it -- `tag = version` -- or a string
    interpolating it behind something like a "v" prefix.
    """
    if not expr.startswith('"'):
        return version
    return INTERPOLATION.sub(version, expr[1:-1])


def source(text: str) -> tuple[str, bool]:
    """The URL to fetch, and whether its hash is over the unpacked tree."""
    version = literal(text, "version")
    if version is None:
        raise Unsupported("no version to resolve the source against")

    match = FETCHER.search(text)
    if match is None:
        raise Unsupported("no fetcher call found")
    fetcher = match.group("body")

    url = attribute(fetcher, "url")
    if url is not None:
        # fetchurl and friends name the file outright, and hash that file
        # rather than an unpacked tree.
        return resolve(url, version), False

    # `owner` and `repo` are often inherited from the derivation, so they fall
    # back to the whole file; `domain` deliberately does not.
    owner = literal(fetcher, "owner") or literal(text, "owner")
    repo = literal(fetcher, "repo") or literal(text, "repo")
    rev = attribute(fetcher, "tag") or attribute(fetcher, "rev")
    if not (owner and repo and rev):
        raise Unsupported("no source to update")

    # GitHub, Forgejo and Gitea all serve a tag's archive from the same path, so
    # the forge enters only as the host name: fetchFromGitea carries it in
    # `domain`, and fetchFromGitHub implies it.
    domain = literal(fetcher, "domain") or "github.com"
    return (
        f"https://{domain}/{owner}/{repo}/archive/{resolve(rev, version)}.tar.gz",
        True,
    )


def rewrite(text: str, hash_: str) -> str:
    """Replace the pinned hash, refusing a file that pins more than one."""
    if len(HASH.findall(text)) != 1:
        raise Unsupported("expected exactly one hashed source")
    return HASH.sub(f'hash = "{hash_}";', text)


def prefetch(url: str, unpack: bool) -> str:
    command = ["nix", "store", "prefetch-file", "--json"]
    if unpack:
        command.append("--unpack")
    command.append(url)
    result = subprocess.run(command, check=True, capture_output=True, text=True)
    return json.loads(result.stdout)["hash"]


def update(path: Path, fetch=prefetch) -> str:
    text = path.read_text()
    url, unpack = source(text)
    path.write_text(rewrite(text, fetch(url, unpack)))
    return url


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("file", type=Path, help="Nix file pinning the source")
    args = parser.parse_args()

    try:
        url = update(args.file)
    except Unsupported as error:
        print(f"{args.file}: {error}", file=sys.stderr)
        return 1
    print(f"{args.file}: rehashed {url}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
