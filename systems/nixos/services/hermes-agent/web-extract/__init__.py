"""Registers the local trafilatura-backed web_extract provider.

hermes imports a user plugin as hermes_plugins.<slug> with the plugin
directory on the module's search path, so the sibling module is reached by
relative import — the plugins.web.* path only works for bundled plugins.
"""

from __future__ import annotations

from .provider import LocalExtractProvider


def register(ctx) -> None:
    ctx.register_web_search_provider(LocalExtractProvider())
