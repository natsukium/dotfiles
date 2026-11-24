import os
import re
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path

from dotcli.lib import Check, DotcliError, info, restart_service, run, wait_until, warn

HELP = "the age key sops-nix decrypts with"


def register(parser, settings):
    actions = parser.add_subparsers(dest="action", required=True)
    p = actions.add_parser(
        "new", help="create or import the key; for a new key, re-encrypt the secrets for it"
    )
    add_new_arguments(p)
    p.set_defaults(func=lambda args: new(args, settings))


def add_new_arguments(parser):
    parser.add_argument(
        "--import", dest="import_from", metavar="FILE", help="import an existing key (- for stdin)"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="replace an existing key; the old one is kept as a .bak file",
    )
    parser.add_argument(
        "--host", help="host name of the &<host>-user anchor in .sops.yaml (default: this machine)"
    )
    parser.add_argument(
        "--repo", help="dotfiles checkout (default: the git repository containing the cwd)"
    )
    parser.add_argument(
        "--no-updatekeys",
        action="store_true",
        help="print the sops updatekeys commands instead of running them",
    )


def hostname():
    return os.uname().nodename.split(".")[0]


def repo_root(explicit=None):
    if explicit:
        root = Path(explicit)
    else:
        r = run(["git", "rev-parse", "--show-toplevel"], check=False)
        if r.returncode != 0:
            return None
        root = Path(r.stdout.strip())
    return root if (root / ".sops.yaml").is_file() else None


def anchor_pattern(anchor):
    return re.compile(rf"^(\s*-\s*&{re.escape(anchor)}\s+)(age1[0-9a-z]+)[ \t]*$", re.MULTILINE)


def stage_key(staged, import_from, age_keygen):
    """Write the new key to staged and return its public key, or raise without leaving it behind."""
    try:
        if import_from:
            try:
                src = sys.stdin.read() if import_from == "-" else Path(import_from).read_text()
            except OSError as e:
                raise DotcliError(f"cannot read {import_from}: {e.strerror}") from e
            fd = os.open(staged, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            with os.fdopen(fd, "w") as f:
                f.write(src if src.endswith("\n") else src + "\n")
        else:
            run([age_keygen, "-o", str(staged)])
        r = run([age_keygen, "-y", str(staged)], check=False)
        if r.returncode != 0 or not r.stdout.strip():
            raise DotcliError(f"not a valid age key: {r.stderr.strip()}")
        return r.stdout.strip()
    except BaseException:
        staged.unlink(missing_ok=True)
        raise


def committed_recipient(root, anchor):
    r = run(["git", "-C", str(root), "show", "HEAD:.sops.yaml"], check=False)
    m = anchor_pattern(anchor).search(r.stdout) if r.returncode == 0 else None
    return m.group(2) if m else None


def replace_recipient(root, anchor, pub):
    """Point &anchor in .sops.yaml at pub.

    Returns None without the anchor, else the files still encrypted for an earlier key.
    The committed recipient counts too: until the files are re-encrypted, a second
    rotation would otherwise only search for the first rotation's key.
    """
    sops_yaml = root / ".sops.yaml"
    text = sops_yaml.read_text()
    m = anchor_pattern(anchor).search(text)
    if m is None:
        return None
    stale = {m.group(2), committed_recipient(root, anchor)} - {None, pub}
    if m.group(2) != pub:
        sops_yaml.write_text(text[: m.start(2)] + pub + text[m.end(2) :])
        info(f"replaced &{anchor} in {sops_yaml}")
    tracked = run(["git", "-C", str(root), "ls-files"]).stdout.splitlines()
    return [
        f
        for f in tracked
        if f != ".sops.yaml"
        and (root / f).is_file()
        and any(key in (root / f).read_text(errors="ignore") for key in stale)
    ]


SOPS_FORMATS = {".yaml", ".yml", ".json", ".ini", ".env"}


def updatekeys_argv(path, sops="sops"):
    # sops picks the store format from the extension; anything else is a binary secret.
    binary = [] if Path(path).suffix in SOPS_FORMATS else ["--input-type", "binary"]
    return [sops, "updatekeys", "-y", *binary, path]


def updatekeys_command(path):
    return shlex.join(updatekeys_argv(path))


def card_present():
    try:
        return run(["gpg", "--card-status"], check=False).returncode == 0
    except FileNotFoundError:
        return False


def wait_for_card():
    """Return True once the smartcard holding the admin PGP key is readable."""
    while not card_present():
        if not sys.stdin.isatty():
            return False
        answer = input("Insert the YubiKey with the admin PGP key and press Enter (s to skip): ")
        if answer.strip().lower() == "s":
            return False
    return True


def reencrypt(root, files, sops):
    """Run sops updatekeys per file and return the files that were not re-encrypted."""
    for i, f in enumerate(files):
        info(f"re-encrypting {f}")
        if subprocess.run(updatekeys_argv(f, sops), check=False, cwd=root).returncode != 0:
            warn(f"sops updatekeys failed for {f}")
            return files[i:]
    return []


def backup_key(key_file):
    for n in range(1000):
        backup = key_file.with_name(key_file.name + (".bak" if n == 0 else f".bak.{n}"))
        try:
            os.link(key_file, backup)
        except FileExistsError:
            continue
        return backup
    raise DotcliError(f"too many backups next to {key_file}")


def new(args, settings):
    key_file = Path(settings["keyFile"])
    if key_file.exists() and not args.force:
        raise DotcliError(f"{key_file} already exists (use --force to replace it)")

    key_file.parent.mkdir(parents=True, exist_ok=True)
    os.chmod(key_file.parent, 0o700)
    with tempfile.TemporaryDirectory(dir=key_file.parent) as tmp:
        staged = Path(tmp) / key_file.name
        pub = stage_key(staged, args.import_from, settings["ageKeygen"])
        if key_file.exists():
            info(f"kept the existing key as {backup_key(key_file)}")
        os.replace(staged, key_file)
    info(f"{'imported' if args.import_from else 'generated'} the key at {key_file}")
    print(f"public key: {pub}")

    if not args.import_from:
        anchor = f"{args.host or hostname()}-user"
        root = repo_root(args.repo)
        files = replace_recipient(root, anchor, pub) if root else None
        if root is None:
            print(
                f"Not inside the dotfiles repository; add {pub} as &{anchor} to .sops.yaml yourself."
            )
        elif files is None:
            print(
                f"No &{anchor} anchor in {root / '.sops.yaml'}. Add it under keys and reference it\n"
                f"from the creation_rules this host should decrypt:\n\n  - &{anchor} {pub}"
            )
        elif files:
            remaining = files
            if not args.no_updatekeys and wait_for_card():
                remaining = reencrypt(root, files, settings["sops"])
            if remaining:
                print(
                    "\nRe-encrypt these files where the admin PGP key or a current recipient\n"
                    "is available:\n\n"
                    + f"  cd {shlex.quote(str(root))}\n"
                    + "".join(f"  {updatekeys_command(f)}\n" for f in remaining)
                )
            print(
                "\nThen commit .sops.yaml with the re-encrypted files and switch home-manager:\n"
                "sops-nix decrypts the copies in the Nix store, not the checkout."
            )

    info(f"restarting {settings['service']}")
    restart_service(settings["service"])
    if wait_until(lambda: Path(settings["secretsDir"]).exists(), 15):
        info(f"secrets decrypted into {settings['secretsDir']}")
    else:
        warn(
            "sops-nix has not decrypted anything yet. For a new key this is expected until the\n"
            "secrets are re-encrypted for it and home-manager is switched again."
        )


def doctor(settings):
    key_file = Path(settings["keyFile"])
    has_key = key_file.exists()
    yield Check(f"age key at {key_file}", has_key, "dotcli age new")

    pub = None
    if has_key:
        r = run([settings["ageKeygen"], "-y", str(key_file)], check=False)
        pub = r.stdout.strip() if r.returncode == 0 else None
        yield Check(f"age key at {key_file} is valid", pub is not None, "dotcli age new --force")

    root = repo_root()
    if pub is not None and root is not None:
        anchor = f"{hostname()}-user"
        m = anchor_pattern(anchor).search((root / ".sops.yaml").read_text())
        if m is not None:
            yield Check(
                f"age key matches &{anchor} in .sops.yaml",
                m.group(2) == pub,
                "the repository encrypts for a different key",
            )

    yield Check(
        f"sops-nix secrets at {settings['secretsDir']}",
        Path(settings["secretsDir"]).exists(),
        f"restart {settings['service']} or switch home-manager",
    )
