"""web_extract backend that shells out to a Nix-built trafilatura extractor.

SearXNG is search-only, and every extract-capable backend hermes ships
(firecrawl, tavily, exa, parallel) is a paid API, so web_extract had no
provider at all. This one keeps extraction local.

The extractor is a separate executable rather than an import: its dependency
closure collides with hermes' sealed venv, and the guest's pkgs.python3 is a
different minor version from the interpreter hermes runs under.
"""

from __future__ import annotations

import json
import logging
import subprocess
from typing import Any, List

from agent.web_search_provider import WebSearchProvider

logger = logging.getLogger(__name__)

EXTRACTOR = "@extractor@"

# Generous because the extractor may fetch, follow a redirect stub, and fall
# back to the reader proxy for each URL in turn.
TIMEOUT = 180


class LocalExtractProvider(WebSearchProvider):
    @property
    def name(self) -> str:
        return "localextract"

    @property
    def display_name(self) -> str:
        return "Local (trafilatura)"

    def is_available(self) -> bool:
        return True

    def supports_search(self) -> bool:
        return False

    def supports_extract(self) -> bool:
        return True

    def extract(self, urls: List[str], **kwargs: Any) -> Any:
        if isinstance(urls, str):
            urls = [urls]
        urls = [u for u in urls if u]
        if not urls:
            return []

        try:
            proc = subprocess.run(
                [EXTRACTOR],
                input=json.dumps(urls),
                capture_output=True,
                text=True,
                timeout=TIMEOUT,
            )
        except subprocess.TimeoutExpired:
            return [_failure(u, f"extractor timed out after {TIMEOUT}s") for u in urls]
        except Exception as exc:  # noqa: BLE001
            return [_failure(u, f"{type(exc).__name__}: {exc}") for u in urls]

        if proc.returncode != 0:
            err = (proc.stderr or "").strip()[:500] or f"exit {proc.returncode}"
            logger.warning("localextract failed: %s", err)
            return [_failure(u, err) for u in urls]

        try:
            results = json.loads(proc.stdout)
        except Exception as exc:  # noqa: BLE001
            return [_failure(u, f"unparsable extractor output: {exc}") for u in urls]
        if not isinstance(results, list):
            return [_failure(u, "extractor did not return a list") for u in urls]
        return results


def _failure(url: str, error: str) -> dict:
    return {
        "url": url,
        "title": "",
        "content": "",
        "raw_content": "",
        "error": error,
    }
