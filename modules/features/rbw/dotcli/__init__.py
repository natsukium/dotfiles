import json
import subprocess
from pathlib import Path

from dotcli.lib import Check, DotcliError, info

HELP = "rbw Bitwarden device registration and login"


def register(parser, settings):
    actions = parser.add_subparsers(dest="action", required=True)
    p = actions.add_parser("login", help="register this device and log in")
    p.set_defaults(func=lambda args: login(settings))


def encode_server(server):
    # Mirrors rbw's INVALID_PATH set: controls, '/', '%' and ':' plus all non-ASCII.
    return "".join(
        f"%{b:02X}" if b < 0x20 or b >= 0x7F or b in b"/%:" else chr(b) for b in server.encode()
    )


def db_file(settings):
    server = settings["baseUrl"] or "default"
    return Path(settings["cacheDir"]) / f"{encode_server(server)}:{settings['email']}.json"


def logged_in(settings):
    try:
        db = json.loads(db_file(settings).read_text())
    except (OSError, ValueError):
        return False
    return bool(db.get("access_token") and db.get("refresh_token"))


def rbw(settings, action):
    # pinentry needs the terminal, so the output is not captured.
    if subprocess.run([settings["rbw"], action], check=False).returncode != 0:
        raise DotcliError(f"`rbw {action}` failed")


def login(settings):
    if logged_in(settings):
        info(f"rbw: already logged in as {settings['email']}")
        return 0

    info(
        "rbw: enter the personal API key (Bitwarden web vault > Account settings > Security > Keys)"
    )
    rbw(settings, "register")
    info("rbw: enter the master password")
    rbw(settings, "login")

    if not logged_in(settings):
        raise DotcliError(f"rbw reported success but {db_file(settings)} has no tokens")
    info(f"rbw: logged in as {settings['email']}")
    return 0


def doctor(settings):
    yield Check(
        f"rbw logged in as {settings['email']}",
        logged_in(settings),
        "dotcli rbw login",
    )
