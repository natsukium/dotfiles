"""Fetch URLs and reduce them to readable text for hermes' web_extract tool.

Runs as a standalone CLI under its own interpreter rather than inside hermes'
Python: trafilatura propagates certifi, charset-normalizer and urllib3, all of
which are already in hermes' sealed uv2nix venv, and the packaging's collision
check fails the build when extraPythonPackages reintroduces them.

Reads a JSON array of URLs on stdin, writes a JSON array of result objects on
stdout in the shape agent/web_search_provider.py documents.
"""

from __future__ import annotations

import json
import re
import sys
from html import unescape
from urllib.parse import urljoin, urlsplit

import httpx
import trafilatura

# Sites that gate on an unknown agent (reddit, several CDNs) serve a challenge
# page instead of content. Discourse does the opposite and hands a browser UA
# the heavy JS shell — 240k instead of 22k — but both render the same text, so
# a browser UA is the safe default.
UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/126.0 Safari/537.36"
)

TIMEOUT = 45

# Below this, an extraction is assumed to have landed on a redirect stub or a
# JS shell rather than on real content, and the fallbacks are tried.
MIN_USEFUL_CHARS = 200

# /t/<slug>/<id> and /t/<id>, optionally with a post number suffix.
DISCOURSE_TOPIC = re.compile(r"^/t/(?:[^/]+/)?(\d+)(?:/\d+)?/?$")

# Both the meta refresh and the "Continue to …" link a redirect stub carries.
REDIRECT_TARGET = re.compile(
    r"""(?:url=|href=)["']?([^"'>\s]+\.html?[^"'>\s]*)""", re.I
)


def client() -> httpx.Client:
    return httpx.Client(
        timeout=TIMEOUT, follow_redirects=True, headers={"User-Agent": UA}
    )


def html_title(html: str) -> str:
    m = re.search(r"<title[^>]*>(.*?)</title>", html, re.S | re.I)
    if not m:
        return ""
    return unescape(re.sub(r"\s+", " ", m.group(1)).strip())


def to_text(html: str, url: str) -> str:
    """Extract with the settings that measured best across Nix/ML/forum pages.

    favor_recall keeps sidebar-adjacent prose that documentation sites put
    outside the main article, and include_tables preserves API parameter
    tables — dropping either loses material the agent was asked to read.
    """
    text = trafilatura.extract(
        html,
        url=url,
        include_comments=True,
        include_tables=True,
        favor_recall=True,
    )
    return text or ""


def discourse_text(url: str, http: httpx.Client) -> tuple[str, str] | None:
    """Return (title, text) for a Discourse topic, or None if this isn't one.

    trafilatura extracts only the opening post of a topic — five posts of HTML
    came back as the first post's 1.1k characters — which silently answers
    "read this thread" with a fraction of the thread. Discourse's own topic
    JSON carries every post, so prefer it and keep the HTML path as fallback.
    """
    parts = urlsplit(url)
    m = DISCOURSE_TOPIC.match(parts.path)
    if not m:
        return None
    api = f"{parts.scheme}://{parts.netloc}/t/{m.group(1)}.json"
    try:
        r = http.get(api)
        r.raise_for_status()
        data = r.json()
    except Exception:
        return None
    posts = (data.get("post_stream") or {}).get("posts")
    if not isinstance(posts, list) or not posts:
        return None

    title = data.get("title") or ""
    chunks = []
    for post in posts:
        body = trafilatura.extract(post.get("cooked") or "", favor_recall=True)
        if not body:
            continue
        who = post.get("username") or "?"
        when = (post.get("created_at") or "")[:10]
        chunks.append(f"## {who} ({when})\n\n{body.strip()}")
    if not chunks:
        return None
    return title, f"# {title}\n\n" + "\n\n".join(chunks)


def follow_stub(html: str, url: str, http: httpx.Client) -> tuple[str, str] | None:
    """Resolve a meta-refresh / JS redirect stub once.

    docs.pytorch.org/docs/stable/… answers with a 1.4k stub whose only text is
    "Continue to ../../2.13/…", so the naive result is a sentence pointing at
    the page the caller actually asked for.
    """
    m = REDIRECT_TARGET.search(html)
    if not m:
        return None
    target = urljoin(url, m.group(1))
    if target.rstrip("/") == url.rstrip("/"):
        return None
    try:
        r = http.get(target)
        r.raise_for_status()
    except Exception:
        return None
    return str(r.url), r.text


def jina_text(url: str, http: httpx.Client) -> str:
    """Last resort for pages that only exist after JavaScript runs.

    search.nixos.org and x.com return an empty shell to a plain fetch; the
    reader proxy renders them. It is rate limited (Discourse probes came back
    503), so it stays behind the local paths rather than replacing them.
    """
    try:
        r = http.get("https://r.jina.ai/" + url)
        r.raise_for_status()
    except Exception:
        return ""
    return r.text


def result(url: str, title: str, text: str) -> dict:
    return {
        "url": url,
        "title": title,
        "content": text,
        # web_tools reads raw_content first and only falls back to content;
        # there is no richer raw form here, so both carry the same text.
        "raw_content": text,
        "metadata": {"chars": len(text)},
    }


def extract_one(url: str, http: httpx.Client) -> dict:
    forum = discourse_text(url, http)
    if forum is not None:
        return result(url, forum[0], forum[1])

    try:
        r = http.get(url)
        r.raise_for_status()
    except Exception as exc:
        return {
            "url": url,
            "title": "",
            "content": "",
            "raw_content": "",
            "error": f"{type(exc).__name__}: {exc}",
        }

    final_url, html = str(r.url), r.text
    text = to_text(html, final_url)

    if len(text) < MIN_USEFUL_CHARS:
        stub = follow_stub(html, final_url, http)
        if stub is not None:
            final_url, html = stub
            text = to_text(html, final_url)

    if len(text) < MIN_USEFUL_CHARS:
        proxied = jina_text(url, http)
        if len(proxied) > len(text):
            return result(final_url, html_title(html), proxied)

    if not text:
        return {
            "url": final_url,
            "title": html_title(html),
            "content": "",
            "raw_content": "",
            "error": "No extractable content (page is likely JavaScript-only)",
        }
    return result(final_url, html_title(html), text)


def main() -> int:
    try:
        urls = json.load(sys.stdin)
    except Exception as exc:
        print(json.dumps({"error": f"bad input: {exc}"}), file=sys.stdout)
        return 1
    if not isinstance(urls, list):
        print(json.dumps({"error": "input must be a JSON array of URLs"}))
        return 1

    with client() as http:
        results = [extract_one(str(u), http) for u in urls]
    json.dump(results, sys.stdout, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
