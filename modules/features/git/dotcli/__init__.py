import json
import os
import subprocess

from dotcli.lib import Check, DotcliError, info, run

HELP = "GitHub CLI accounts, one gh config directory each"


def register(parser, settings):
    actions = parser.add_subparsers(dest="action", required=True)
    p = actions.add_parser("login", help="log each account in through the browser")
    p.add_argument("accounts", nargs="*", help="accounts to log in (default: all configured)")
    p.set_defaults(func=lambda args: login(args.accounts, settings))


def env(account):
    return {**os.environ, "GH_CONFIG_DIR": account["configDir"]}


def current_user(settings, account):
    r = run(
        [
            settings["gh"],
            "auth",
            "status",
            "--active",
            "--hostname",
            settings["host"],
            "--json",
            "hosts",
        ],
        check=False,
        env=env(account),
    )
    try:
        entries = json.loads(r.stdout)["hosts"].get(settings["host"], [])
    except (ValueError, KeyError, AttributeError):
        return None
    for e in entries:
        if e.get("active") and e.get("state") == "success":
            return e.get("login")
    return None


def select(settings, names):
    accounts = settings["accounts"]
    unknown = [n for n in names if n not in accounts]
    if unknown:
        raise DotcliError(f"unknown account(s): {', '.join(unknown)}; known: {', '.join(accounts)}")
    return {n: accounts[n] for n in (names or accounts)}


def logout_hint(settings, account):
    return f"GH_CONFIG_DIR={account['configDir']} gh auth logout --hostname {settings['host']}"


def login_one(settings, name, account):
    user = current_user(settings, account)
    if user == account["user"]:
        info(f"gh ({name}): already logged in as {user}")
        return
    if user is not None:
        raise DotcliError(
            f"gh ({name}): logged in as {user}, expected {account['user']}; "
            f"run `{logout_hint(settings, account)}` first"
        )

    # The browser's GitHub session decides which account gets authorized, so a
    # login for the second account silently authorizes the first one.
    info(f"gh ({name}): authorize as {account['user']}; switch the browser's GitHub account first")
    cmd = [
        settings["gh"],
        "auth",
        "login",
        "--hostname",
        settings["host"],
        "--git-protocol",
        "https",
        "--web",
        "--skip-ssh-key",
    ]
    if account.get("scopes"):
        cmd += ["--scopes", ",".join(account["scopes"])]
    if subprocess.run(cmd, check=False, env=env(account)).returncode != 0:
        raise DotcliError(f"gh ({name}): `gh auth login` failed")

    user = current_user(settings, account)
    if user != account["user"]:
        raise DotcliError(
            f"gh ({name}): authorized as {user}, expected {account['user']}; "
            f"run `{logout_hint(settings, account)}` and retry with the right browser session"
        )
    info(f"gh ({name}): logged in as {user}")


def login(names, settings):
    for name, account in select(settings, names).items():
        login_one(settings, name, account)
    return 0


def doctor(settings):
    for name, account in settings["accounts"].items():
        user = current_user(settings, account)
        yield Check(
            f"gh ({name}) logged in as {account['user']}",
            user == account["user"],
            f"dotcli gh login {name}"
            if user is None
            else f"logged in as {user}; {logout_hint(settings, account)}",
        )
