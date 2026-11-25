import argparse
import json
import shutil
import stat
import subprocess
import sys

import pytest

from dotcli import lib
from dotcli.lib import DotcliError
from dotcli.plugins import age

OLD_KEY = "age1" + "q" * 58
OTHER_KEY = "age1" + "p" * 58


@pytest.fixture(autouse=True)
def outside_any_repo(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)


@pytest.fixture
def settings(tmp_path):
    return {
        "keyFile": str(tmp_path / "config/sops/age/keys.txt"),
        "secretsDir": str(tmp_path / "secrets"),
        "service": "sops-nix",
        "ageKeygen": shutil.which("age-keygen"),
        "sops": str(fake_sops(tmp_path)),
    }


FAKE_SOPS = """
import json, os, sys
from pathlib import Path

here = Path(sys.argv[0]).parent
with open(here / "sops-calls.jsonl", "a") as log:
    log.write(json.dumps({"argv": sys.argv[1:], "cwd": os.getcwd()}) + "\\n")
fail = here / "sops-fail-on"
sys.exit(1 if fail.exists() and fail.read_text() == sys.argv[-1] else 0)
"""


def fake_sops(tmp_path):
    exe = tmp_path / "sops"
    exe.write_text(f"#!{sys.executable}\n" + FAKE_SOPS)
    exe.chmod(0o755)
    return exe


def sops_calls(tmp_path):
    log = tmp_path / "sops-calls.jsonl"
    return [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []


@pytest.fixture(autouse=True)
def yubikey(monkeypatch):
    state = {"present": False}
    monkeypatch.setattr(age, "card_present", lambda: state["present"])
    return state


@pytest.fixture
def restarted(monkeypatch):
    calls = []
    monkeypatch.setattr(age, "restart_service", calls.append)
    monkeypatch.setattr(age, "wait_until", lambda pred, timeout: lib.wait_until(pred, 0))
    return calls


@pytest.fixture
def repo(tmp_path):
    root = tmp_path / "repo"
    root.mkdir()
    (root / ".sops.yaml").write_text(
        f"keys:\n  - &work-user {OLD_KEY}\n  - &other-user {OTHER_KEY}\ncreation_rules: []\n"
    )
    (root / "secrets.yaml").write_text(f"sops:\n  age:\n    - recipient: {OLD_KEY}\n")
    (root / "with space.yaml").write_text(f"sops:\n  age:\n    - recipient: {OLD_KEY}\n")
    (root / "other.yaml").write_text(f"sops:\n  age:\n    - recipient: {OTHER_KEY}\n")
    subprocess.run(["git", "init", "-q", str(root)], check=True)
    subprocess.run(["git", "-C", str(root), "add", "-A"], check=True)
    subprocess.run(
        [
            "git",
            "-C",
            str(root),
            "-c",
            "user.name=t",
            "-c",
            "user.email=t@example.com",
            "commit",
            "-qm",
            "init",
        ],
        check=True,
    )
    return root


def public_key(settings):
    return subprocess.run(
        [settings["ageKeygen"], "-y", settings["keyFile"]],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


def parse(*argv):
    parser = argparse.ArgumentParser()
    age.add_new_arguments(parser)
    return parser.parse_args(argv)


def test_new_generates_private_key_and_restarts_sops_nix(settings, restarted, tmp_path, capsys):
    age.new(parse("--repo", str(tmp_path)), settings)

    key = tmp_path / "config/sops/age/keys.txt"
    assert "AGE-SECRET-KEY-" in key.read_text()
    assert stat.S_IMODE(key.parent.stat().st_mode) == 0o700
    assert f"public key: {public_key(settings)}" in capsys.readouterr().out
    assert restarted == ["sops-nix"]


def test_new_refuses_to_overwrite_existing_key(settings, restarted):
    age.new(parse(), settings)

    with pytest.raises(DotcliError, match="already exists"):
        age.new(parse(), settings)


def test_new_force_keeps_previous_key_as_backup(settings, restarted, tmp_path):
    age.new(parse(), settings)
    key = tmp_path / "config/sops/age/keys.txt"
    previous = key.read_text()

    age.new(parse("--force"), settings)

    assert (tmp_path / "config/sops/age/keys.txt.bak").read_text() == previous
    assert key.read_text() != previous


def test_new_force_never_overwrites_an_earlier_backup(settings, restarted, tmp_path):
    key = tmp_path / "config/sops/age/keys.txt"
    generations = []
    for argv in [(), ("--force",), ("--force",)]:
        age.new(parse(*argv), settings)
        generations.append(key.read_text())

    assert (tmp_path / "config/sops/age/keys.txt.bak").read_text() == generations[0]
    assert (tmp_path / "config/sops/age/keys.txt.bak.1").read_text() == generations[1]


def test_new_force_keeps_working_key_when_installing_replacement_fails(
    settings, restarted, tmp_path, monkeypatch
):
    age.new(parse(), settings)
    key = tmp_path / "config/sops/age/keys.txt"
    working = key.read_text()

    def failing_replace(src, dst):
        raise OSError("disk full")

    monkeypatch.setattr(age.os, "replace", failing_replace)

    with pytest.raises(OSError):
        age.new(parse("--force"), settings)

    assert key.read_text() == working


def test_new_imports_existing_key_with_owner_only_permissions(settings, restarted, tmp_path, repo):
    source = tmp_path / "old-keys.txt"
    subprocess.run([settings["ageKeygen"], "-o", str(source)], check=True, capture_output=True)
    sops_yaml = (repo / ".sops.yaml").read_text()

    age.new(parse("--import", str(source), "--repo", str(repo), "--host", "work"), settings)

    key = tmp_path / "config/sops/age/keys.txt"
    assert key.read_text() == source.read_text()
    assert stat.S_IMODE(key.stat().st_mode) == 0o600
    assert (repo / ".sops.yaml").read_text() == sops_yaml


def test_new_import_rejects_input_that_is_not_an_age_key(settings, restarted, tmp_path):
    source = tmp_path / "not-a-key.txt"
    source.write_text("AGE-SECRET-KEY-NOTREALLY\n")

    with pytest.raises(DotcliError, match="not a valid age key"):
        age.new(parse("--import", str(source)), settings)
    assert list((tmp_path / "config/sops/age").iterdir()) == []


@pytest.mark.parametrize(
    "content", [None, "AGE-SECRET-KEY-NOTREALLY\n"], ids=["missing", "invalid"]
)
def test_new_force_import_of_bad_input_keeps_the_working_key(
    settings, restarted, tmp_path, content
):
    age.new(parse(), settings)
    key_dir = tmp_path / "config/sops/age"
    working = (key_dir / "keys.txt").read_text()
    source = tmp_path / "bad-keys.txt"
    if content is not None:
        source.write_text(content)

    with pytest.raises(DotcliError):
        age.new(parse("--force", "--import", str(source)), settings)

    assert (key_dir / "keys.txt").read_text() == working
    assert sorted(p.name for p in key_dir.iterdir()) == ["keys.txt"]


def test_new_points_host_anchor_at_generated_key(settings, restarted, repo, capsys):
    age.new(parse("--repo", str(repo), "--host", "work"), settings)

    pub = public_key(settings)
    text = (repo / ".sops.yaml").read_text()
    assert f"&work-user {pub}\n" in text
    assert f"&other-user {OTHER_KEY}\n" in text
    out = capsys.readouterr().out
    assert f"  cd {repo}\n  sops updatekeys -y" in out
    assert "  sops updatekeys -y secrets.yaml\n" in out
    assert "  sops updatekeys -y 'with space.yaml'\n" in out


def test_replace_recipient_lists_only_files_encrypted_for_old_key(repo):
    assert sorted(age.replace_recipient(repo, "work-user", "age1new")) == [
        "secrets.yaml",
        "with space.yaml",
    ]


def test_second_rotation_before_reencryption_still_lists_files_for_committed_key(
    settings, restarted, repo, capsys
):
    age.new(parse("--repo", str(repo), "--host", "work"), settings)
    capsys.readouterr()

    age.new(parse("--force", "--repo", str(repo), "--host", "work"), settings)

    assert "  sops updatekeys -y secrets.yaml\n" in capsys.readouterr().out


@pytest.mark.parametrize(
    "path, command",
    [
        ("secrets.yaml", "sops updatekeys -y secrets.yaml"),
        ("a/b.json", "sops updatekeys -y a/b.json"),
        ("hosts/work/agents.md", "sops updatekeys -y --input-type binary hosts/work/agents.md"),
        ("with space.yaml", "sops updatekeys -y 'with space.yaml'"),
    ],
)
def test_updatekeys_command_marks_non_structured_files_as_binary(path, command):
    assert age.updatekeys_command(path) == command


def test_new_reencrypts_each_stale_file_from_repo_root_when_yubikey_is_present(
    settings, restarted, repo, tmp_path, yubikey, capsys
):
    yubikey["present"] = True

    age.new(parse("--repo", str(repo), "--host", "work"), settings)

    calls = sops_calls(tmp_path)
    assert sorted(c["argv"][-1] for c in calls) == ["secrets.yaml", "with space.yaml"]
    assert all(c["argv"][:2] == ["updatekeys", "-y"] for c in calls)
    assert all(c["cwd"] == str(repo) for c in calls)
    out = capsys.readouterr().out
    assert "sops updatekeys -y" not in out
    assert "switch home-manager" in out


def test_new_stops_at_failed_reencryption_and_prints_it_with_the_rest(
    settings, restarted, repo, tmp_path, yubikey, capsys
):
    yubikey["present"] = True
    (tmp_path / "sops-fail-on").write_text("secrets.yaml")

    age.new(parse("--repo", str(repo), "--host", "work"), settings)

    assert [c["argv"][-1] for c in sops_calls(tmp_path)] == ["secrets.yaml"]
    out = capsys.readouterr().out
    assert "  sops updatekeys -y secrets.yaml\n" in out
    assert "  sops updatekeys -y 'with space.yaml'\n" in out


def test_new_no_updatekeys_only_prints_commands(
    settings, restarted, repo, tmp_path, yubikey, capsys
):
    yubikey["present"] = True

    age.new(parse("--repo", str(repo), "--host", "work", "--no-updatekeys"), settings)

    assert sops_calls(tmp_path) == []
    assert "  sops updatekeys -y secrets.yaml\n" in capsys.readouterr().out


def test_new_without_yubikey_on_non_interactive_stdin_prints_commands(
    settings, restarted, repo, tmp_path, capsys
):
    age.new(parse("--repo", str(repo), "--host", "work"), settings)

    assert sops_calls(tmp_path) == []
    assert "  sops updatekeys -y secrets.yaml\n" in capsys.readouterr().out


def test_wait_for_card_prompts_until_yubikey_is_inserted(monkeypatch, yubikey):
    monkeypatch.setattr(age.sys.stdin, "isatty", lambda: True, raising=False)
    prompts = []

    def insert_on_second_prompt(prompt):
        prompts.append(prompt)
        yubikey["present"] = len(prompts) == 2
        return ""

    monkeypatch.setattr("builtins.input", insert_on_second_prompt)

    assert age.wait_for_card() is True
    assert len(prompts) == 2


def test_wait_for_card_can_be_skipped(monkeypatch):
    monkeypatch.setattr(age.sys.stdin, "isatty", lambda: True, raising=False)
    monkeypatch.setattr("builtins.input", lambda prompt: "s")

    assert age.wait_for_card() is False


def test_replace_recipient_without_anchor_returns_none(repo):
    assert age.replace_recipient(repo, "missing-user", "age1new") is None


def test_replace_recipient_with_same_key_changes_nothing(repo):
    before = (repo / ".sops.yaml").read_text()

    assert age.replace_recipient(repo, "work-user", OLD_KEY) == []
    assert (repo / ".sops.yaml").read_text() == before


def test_doctor_reports_missing_key(settings, monkeypatch):
    monkeypatch.setattr(age, "repo_root", lambda explicit=None: None)

    checks = list(age.doctor(settings))

    assert [c.ok for c in checks] == [False, False]
    assert checks[0].hint == "dotcli age new"


def test_doctor_reports_malformed_key_instead_of_crashing(settings, tmp_path, monkeypatch):
    monkeypatch.setattr(age, "repo_root", lambda explicit=None: None)
    key = tmp_path / "config/sops/age/keys.txt"
    key.parent.mkdir(parents=True)
    key.write_text("garbage\n")

    checks = {c.label: c.ok for c in age.doctor(settings)}

    assert checks[f"age key at {key}"] is True
    assert checks[f"age key at {key} is valid"] is False


def test_doctor_flags_key_that_differs_from_repository_anchor(
    settings, restarted, repo, monkeypatch
):
    age.new(parse(), settings)
    monkeypatch.setattr(age, "repo_root", lambda explicit=None: repo)
    monkeypatch.setattr(age, "hostname", lambda: "work")

    checks = {c.label: c.ok for c in age.doctor(settings)}

    assert checks["age key matches &work-user in .sops.yaml"] is False


def test_register_exposes_new_as_age_action(settings, restarted, tmp_path):
    parser = argparse.ArgumentParser()
    age.register(parser, settings)

    args = parser.parse_args(["new", "--repo", str(tmp_path)])
    args.func(args)

    assert (tmp_path / "config/sops/age/keys.txt").exists()
