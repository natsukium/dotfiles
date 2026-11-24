import argparse
import importlib
import json
import sys
from pathlib import Path

from dotcli.lib import DotcliError


def load_plugins(config_path):
    config = json.loads(Path(config_path).read_text())
    return {
        name: (importlib.import_module(f"dotcli.plugins.{name}"), settings)
        for name, settings in config.items()
    }


def build_parser(plugins):
    parser = argparse.ArgumentParser(
        prog="dotcli",
        description="Imperative operations this dotfiles configuration cannot declare.",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    for name, (module, settings) in plugins.items():
        module.register(sub.add_parser(name, help=module.HELP), settings)

    doctor = sub.add_parser("doctor", help="report what is still missing on this machine")
    doctor.set_defaults(func=lambda args: doctor_all(plugins))
    return parser


def doctor_all(plugins):
    ok = True
    for module, settings in plugins.values():
        for check in module.doctor(settings):
            ok &= check.ok
            hint = f"  ({check.hint})" if check.hint and not check.ok else ""
            print(f"[{'ok' if check.ok else 'NG'}] {check.label}{hint}")
    return 0 if ok else 1


def main(config_path, argv=None):
    sys.stdout.reconfigure(line_buffering=True)
    plugins = load_plugins(config_path)
    args = build_parser(plugins).parse_args(argv)
    try:
        return args.func(args) or 0
    except DotcliError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
