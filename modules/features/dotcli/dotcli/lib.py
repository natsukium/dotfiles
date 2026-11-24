import os
import subprocess
import sys
import time
from dataclasses import dataclass


class DotcliError(Exception):
    pass


@dataclass
class Check:
    label: str
    ok: bool
    hint: str = ""


def info(msg):
    print(f"==> {msg}")


def warn(msg):
    print(f"warning: {msg}", file=sys.stderr)


def run(cmd, check=True, **kwargs):
    return subprocess.run(cmd, check=check, capture_output=True, text=True, **kwargs)


def wait_until(pred, timeout, interval=1.0):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if pred():
            return True
        time.sleep(interval)
    return pred()


def service_command(name, platform=sys.platform):
    if platform == "darwin":
        return ["launchctl", "kickstart", "-k", f"gui/{os.getuid()}/org.nix-community.home.{name}"]
    return ["systemctl", "--user", "restart", f"{name}.service"]


def restart_service(name):
    r = run(service_command(name), check=False)
    if r.returncode != 0:
        raise DotcliError(f"failed to restart {name}: {r.stderr.strip()}")
