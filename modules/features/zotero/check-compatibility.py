#!/usr/bin/env python3
"""Check that a Zotero plugin covers the Zotero version it is installed beside.

Zotero does not refuse a plugin that falls outside the range its manifest
declares: it starts, leaves the plugin disabled and says nothing, so the break
only surfaces the next time you reach for the plugin.
"""

import json
import re
import sys
import zipfile


def parts(version: str, wildcard: float) -> tuple[float, ...]:
    """A dotted version as comparable numbers, with `*` standing for wildcard.

    A bound is padded by comparison rather than by length: `8.*` becomes
    `(8, inf)`, which sorts above every `8.x` and below `9`.
    """
    numbers = []
    for part in version.split("."):
        if part == "*":
            numbers.append(wildcard)
        else:
            digits = re.match(r"\d+", part)
            numbers.append(int(digits.group()) if digits else 0)
    return tuple(numbers)


def main() -> int:
    xpi, pinned, zotero = sys.argv[1:4]

    with zipfile.ZipFile(xpi) as archive:
        manifest = json.loads(archive.read("manifest.json"))

    name = manifest.get("name", "plugin")

    if manifest["version"] != pinned:
        print(
            f"{name}: manifest reads {manifest['version']}, but the expression pins {pinned}",
            file=sys.stderr,
        )
        return 1

    supported = manifest["applications"]["zotero"]
    low, high = supported["strict_min_version"], supported["strict_max_version"]

    if not parts(low, 0) <= parts(zotero, 0) <= parts(high, float("inf")):
        print(
            f"{name} {pinned} loads in Zotero {low} to {high}, but nixpkgs ships {zotero}",
            file=sys.stderr,
        )
        return 1

    print(f"{name} {pinned} loads in Zotero {low} to {high}; nixpkgs ships {zotero}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
