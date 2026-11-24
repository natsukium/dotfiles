import re
import webbrowser
from pathlib import Path

from dotcli.lib import Check, DotcliError, info, restart_service, run, wait_until, warn

HELP = "pizauth OAuth accounts"

URL_RE = re.compile(r"https?://\S+")


def register(parser, settings):
    actions = parser.add_subparsers(dest="action", required=True)
    p = actions.add_parser("login", help="authorize accounts in the browser")
    add_login_arguments(p)
    p.set_defaults(func=lambda args: login(args, settings))


def add_login_arguments(parser):
    parser.add_argument(
        "accounts", nargs="*", help="accounts to authorize (default: all configured)"
    )
    parser.add_argument(
        "--no-browser", action="store_true", help="print the URL without opening it"
    )
    parser.add_argument(
        "--timeout", type=float, default=300, help="seconds to wait per account (default: 300)"
    )


def running(settings):
    return run([settings["pizauth"], "status"], check=False).returncode == 0


def has_token(settings, account):
    return run([settings["pizauth"], "show", "-u", account], check=False).returncode == 0


def authorize(settings, account, open_browser, timeout):
    if has_token(settings, account):
        info(f"{account}: already authorized")
        return True

    r = run([settings["pizauth"], "show", account], check=False)
    m = URL_RE.search(r.stderr)
    if m is None:
        # No URL means pizauth still holds a refresh token and started refreshing.
        if wait_until(lambda: has_token(settings, account), 10):
            info(f"{account}: token refreshed")
            return True
        warn(f"{account}: pizauth gave no authorization URL: {r.stderr.strip()}")
        return False

    url = m.group(0)
    info(f"{account}: authorize in the browser")
    print(url)
    if open_browser:
        webbrowser.open(url)

    if wait_until(lambda: has_token(settings, account), timeout):
        info(f"{account}: authorized")
        return True
    warn(f"{account}: timed out waiting for authorization")
    return False


def login(args, settings):
    if not Path(settings["configFile"]).exists():
        raise DotcliError(
            f"{settings['configFile']} is missing; sops-nix has not rendered it (run `dotcli age new` first)"
        )

    if not running(settings):
        info(f"starting {settings['service']}")
        restart_service(settings["service"])
        if not wait_until(lambda: running(settings), 30):
            raise DotcliError("pizauth did not come up; check its logs")

    known = settings["accounts"]
    targets = args.accounts or known
    unknown = sorted(set(targets) - set(known))
    if unknown:
        raise DotcliError(
            f"unknown account(s): {', '.join(unknown)} (configured: {', '.join(known)})"
        )

    results = [authorize(settings, a, not args.no_browser, args.timeout) for a in targets]

    dump = settings["dumpFile"]
    if dump is not None:
        if wait_until(lambda: Path(dump).exists(), 10):
            info(f"tokens persisted to {dump}")
        else:
            warn(f"{dump} was not written; tokens will not survive a restart")
    return 0 if all(results) else 1


def doctor(settings):
    has_conf = Path(settings["configFile"]).exists()
    yield Check(f"pizauth config at {settings['configFile']}", has_conf, "rendered by sops-nix")
    is_running = running(settings)
    yield Check("pizauth server running", is_running, "dotcli pizauth login")
    if is_running:
        for account in settings["accounts"]:
            yield Check(
                f"pizauth account {account} authorized",
                has_token(settings, account),
                "dotcli pizauth login",
            )
    if settings["dumpFile"] is not None:
        yield Check(
            f"pizauth token dump at {settings['dumpFile']}",
            Path(settings["dumpFile"]).exists(),
            "written after the first authorization",
        )
