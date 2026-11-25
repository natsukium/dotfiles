import argparse
import json
import sys
import textwrap

import pytest

from dotcli.lib import DotcliError
from dotcli.plugins import rbw

FAKE_RBW = textwrap.dedent(
    """\
    import json
    import sys
    from pathlib import Path

    here = Path(sys.argv[0]).parent
    action = sys.argv[1]
    with open(here / "calls", "a") as f:
        f.write(action + "\\n")
    if (here / f"fail-{action}").exists():
        sys.exit(1)
    if action == "login" and not (here / "no-tokens").exists():
        db = here / "cache" / "default:me@example.com.json"
        db.write_text(json.dumps({"access_token": "a", "refresh_token": "r"}))
    """
)


@pytest.fixture
def settings(tmp_path):
    exe = tmp_path / "rbw"
    exe.write_text(f"#!{sys.executable}\n" + FAKE_RBW)
    exe.chmod(0o755)
    (tmp_path / "cache").mkdir()
    return {
        "rbw": str(exe),
        "email": "me@example.com",
        "baseUrl": None,
        "cacheDir": str(tmp_path / "cache"),
    }


def calls(tmp_path):
    f = tmp_path / "calls"
    return f.read_text().split() if f.exists() else []


def test_login_registers_device_then_logs_in(settings, tmp_path):
    assert rbw.login(settings) == 0
    assert calls(tmp_path) == ["register", "login"]


def test_login_is_a_noop_when_tokens_exist(settings, tmp_path):
    (tmp_path / "cache" / "default:me@example.com.json").write_text(
        json.dumps({"access_token": "a", "refresh_token": "r"})
    )

    assert rbw.login(settings) == 0
    assert calls(tmp_path) == []


def test_login_stops_when_register_fails(settings, tmp_path):
    (tmp_path / "fail-register").touch()

    with pytest.raises(DotcliError, match="rbw register"):
        rbw.login(settings)
    assert calls(tmp_path) == ["register"]


def test_login_fails_when_no_tokens_were_saved(settings, tmp_path):
    (tmp_path / "no-tokens").touch()

    with pytest.raises(DotcliError, match="has no tokens"):
        rbw.login(settings)


def test_db_file_percent_encodes_custom_server_like_rbw(settings):
    settings["baseUrl"] = "https://vault.example:8443/"

    assert rbw.db_file(settings).name == "https%3A%2F%2Fvault.example%3A8443%2F:me@example.com.json"


def test_doctor_reports_logged_out_db_without_tokens(settings, tmp_path):
    (tmp_path / "cache" / "default:me@example.com.json").write_text(
        json.dumps({"access_token": None, "refresh_token": None})
    )

    assert [c.ok for c in rbw.doctor(settings)] == [False]


def test_register_exposes_login_as_rbw_action(settings, tmp_path):
    parser = argparse.ArgumentParser()
    rbw.register(parser, settings)

    args = parser.parse_args(["login"])

    assert args.func(args) == 0
    assert calls(tmp_path) == ["register", "login"]
