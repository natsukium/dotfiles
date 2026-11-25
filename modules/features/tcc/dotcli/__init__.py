import os
import sqlite3
import subprocess
import tempfile
from pathlib import Path

from dotcli.lib import Check, DotcliError, info, run

HELP = "macOS privacy permissions (TCC) that app bundles need"

# name: (TCC service, System Settings anchor)
SERVICES = {
    "Accessibility": ("kTCCServiceAccessibility", "Privacy_Accessibility"),
    "FullDiskAccess": ("kTCCServiceSystemPolicyAllFiles", "Privacy_AllFiles"),
    "InputMonitoring": ("kTCCServiceListenEvent", "Privacy_ListenEvent"),
    "Microphone": ("kTCCServiceMicrophone", "Privacy_Microphone"),
    "ScreenRecording": ("kTCCServiceScreenCapture", "Privacy_ScreenCapture"),
}

ALLOWED = 2


def register(parser, settings):
    actions = parser.add_subparsers(dest="action", required=True)
    p = actions.add_parser("grant", help="open System Settings for each missing permission")
    p.set_defaults(func=lambda args: grant(settings))


class Unreadable(Exception):
    pass


def read_entries(databases):
    """Map (client, service) to (auth_value, csreq blob) across all databases."""
    entries = {}
    for db in databases:
        if not Path(db).exists():
            continue
        try:
            con = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
            try:
                rows = con.execute(
                    "select client, service, auth_value, csreq from access"
                ).fetchall()
            finally:
                con.close()
        except sqlite3.Error as e:
            raise Unreadable(f"{db}: {e}") from e
        for client, service, auth, req in rows:
            entries[(client, service)] = (auth, req)
    return entries


def bundle_of(executable):
    p = Path(os.path.realpath(executable))
    for parent in [p, *p.parents]:
        if parent.suffix == ".app":
            return parent
    raise DotcliError(f"{executable} is not inside an .app bundle")


def designated_requirement(settings, bundle):
    r = run([settings["codesign"], "-d", "-r-", str(bundle)], check=False)
    for line in (r.stdout + r.stderr).splitlines():
        if line.startswith("designated => "):
            return line.removeprefix("designated => ").strip()
    return None


def decode_requirement(settings, blob):
    with tempfile.NamedTemporaryFile() as f:
        f.write(blob)
        f.flush()
        r = run([settings["csreq"], "-r", f.name, "-t"], check=False)
    return r.stdout.strip() if r.returncode == 0 else None


def status(settings, entries, client, grant, service):
    """Return None when granted, otherwise why not."""
    auth, blob = entries.get((client, SERVICES[service][0]), (None, None))
    if auth != ALLOWED:
        return "not granted"
    want = designated_requirement(settings, bundle_of(grant["executable"]))
    if blob is not None and want is not None and decode_requirement(settings, blob) != want:
        return "granted to an older signature; remove the entry and add the app again"
    return None


def missing(settings):
    entries = read_entries(settings["databases"])
    for client, grant in settings["grants"].items():
        for service in grant["services"]:
            why = status(settings, entries, client, grant, service)
            if why is not None:
                yield client, grant, service, why


def unreadable_message(e):
    return f"cannot read the TCC database ({e}); grant Full Disk Access to this terminal"


def macos_open(*args):
    subprocess.run(["open", *args], check=False)


def grant(settings):
    try:
        todo = list(missing(settings))
    except Unreadable as e:
        raise DotcliError(unreadable_message(e)) from e
    if not todo:
        info("tcc: every permission is granted")
        return 0

    for client, g, service, why in todo:
        bundle = bundle_of(g["executable"])
        info(f"{client}: {service} {why}")
        print(f"  add with + and Cmd-Shift-G, or drag from Finder: {bundle}")
        anchor = SERVICES[service][1]
        macos_open(f"x-apple.systempreferences:com.apple.preference.security?{anchor}")
        macos_open("-R", str(bundle))
        input("  press Enter when done ")

    left = list(missing(settings))
    for client, _, service, why in left:
        info(f"{client}: {service} still {why}")
    return 1 if left else 0


def doctor(settings):
    try:
        entries = read_entries(settings["databases"])
    except Unreadable as e:
        yield Check("TCC database readable", False, unreadable_message(e))
        return
    for client, g in settings["grants"].items():
        for service in g["services"]:
            why = status(settings, entries, client, g, service)
            yield Check(f"{client} has {service}", why is None, f"{why}; dotcli tcc grant")
