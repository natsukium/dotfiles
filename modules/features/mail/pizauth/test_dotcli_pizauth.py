import argparse
import sys
import textwrap

import pytest
from dotcli import lib
from dotcli.lib import DotcliError
from dotcli.plugins import pizauth

FAKE_PIZAUTH = textwrap.dedent(
    """\
    import sys
    from pathlib import Path

    state = Path(sys.argv[0]).parent / "state"
    args = sys.argv[1:]
    if args == ["status"]:
        sys.exit(0 if (state / "running").exists() else 1)
    if args[0] == "show":
        account = args[-1]
        if (state / f"token-{account}").exists():
            print("token")
            sys.exit(0)
        if "-u" in args:
            sys.exit(1)
        if (state / f"refresh-{account}").exists():
            (state / f"token-{account}").touch()
            sys.exit(1)
        print(f"{account}: access token unavailable until authorised with URL https://auth.example/{account}?x=1", file=sys.stderr)
        sys.exit(1)
    sys.exit(2)
    """
)


@pytest.fixture
def state(tmp_path):
    (tmp_path / "state").mkdir()
    return tmp_path / "state"


@pytest.fixture
def settings(tmp_path, state):
    exe = tmp_path / "pizauth"
    exe.write_text(f"#!{sys.executable}\n" + FAKE_PIZAUTH)
    exe.chmod(0o755)
    conf = tmp_path / "pizauth.conf"
    conf.write_text("")
    (state / "running").touch()
    return {
        "pizauth": str(exe),
        "configFile": str(conf),
        "accounts": ["gmail", "work"],
        "dumpFile": None,
        "service": "pizauth",
    }


@pytest.fixture(autouse=True)
def fast_wait(monkeypatch):
    monkeypatch.setattr(
        pizauth, "wait_until", lambda pred, timeout: lib.wait_until(pred, min(timeout, 1), 0.01)
    )


@pytest.fixture
def browser(monkeypatch, state):
    opened = []

    def open_url(url):
        opened.append(url)
        account = url.split("/")[-1].split("?")[0]
        (state / f"token-{account}").touch()

    monkeypatch.setattr(pizauth.webbrowser, "open", open_url)
    return opened


def parse(*argv):
    parser = argparse.ArgumentParser()
    pizauth.add_login_arguments(parser)
    return parser.parse_args(argv)


def test_login_opens_authorization_url_for_each_account_and_waits_for_token(settings, browser):
    assert pizauth.login(parse(), settings) == 0
    assert browser == ["https://auth.example/gmail?x=1", "https://auth.example/work?x=1"]


def test_login_skips_accounts_that_already_have_a_token(settings, state, browser):
    (state / "token-gmail").touch()

    assert pizauth.login(parse(), settings) == 0
    assert browser == ["https://auth.example/work?x=1"]


def test_login_restricts_to_named_accounts(settings, browser):
    assert pizauth.login(parse("work"), settings) == 0
    assert browser == ["https://auth.example/work?x=1"]


def test_login_accepts_refresh_without_url(settings, state, browser):
    (state / "refresh-gmail").touch()

    assert pizauth.login(parse("gmail"), settings) == 0
    assert browser == []


def test_login_no_browser_prints_url_and_fails_on_timeout(settings, browser, capsys):
    assert pizauth.login(parse("--no-browser", "--timeout", "0", "gmail"), settings) == 1
    assert browser == []
    assert "https://auth.example/gmail?x=1" in capsys.readouterr().out


def test_login_rejects_unknown_account(settings, browser):
    with pytest.raises(DotcliError, match="unknown account"):
        pizauth.login(parse("nope"), settings)


def test_login_requires_rendered_config(settings, tmp_path, browser):
    (tmp_path / "pizauth.conf").unlink()

    with pytest.raises(DotcliError, match="dotcli age new"):
        pizauth.login(parse(), settings)


def test_login_starts_daemon_when_not_running(settings, state, browser, monkeypatch):
    (state / "running").unlink()
    restarted = []

    def restart(name):
        restarted.append(name)
        (state / "running").touch()

    monkeypatch.setattr(pizauth, "restart_service", restart)

    assert pizauth.login(parse(), settings) == 0
    assert restarted == ["pizauth"]


def test_login_warns_when_dump_is_not_written(settings, tmp_path, browser, capsys):
    settings["dumpFile"] = str(tmp_path / "dump.age")

    assert pizauth.login(parse(), settings) == 0
    assert "will not survive a restart" in capsys.readouterr().err


def test_doctor_checks_each_account_while_daemon_runs(settings, state):
    (state / "token-gmail").touch()

    checks = {c.label: c.ok for c in pizauth.doctor(settings)}

    assert checks == {
        f"pizauth config at {settings['configFile']}": True,
        "pizauth server running": True,
        "pizauth account gmail authorized": True,
        "pizauth account work authorized": False,
    }


def test_doctor_skips_account_checks_when_daemon_is_down(settings, state):
    (state / "running").unlink()

    labels = [c.label for c in pizauth.doctor(settings)]

    assert not any(label.startswith("pizauth account") for label in labels)


def test_register_exposes_login_as_pizauth_action(settings, browser):
    parser = argparse.ArgumentParser()
    pizauth.register(parser, settings)

    args = parser.parse_args(["login", "work"])

    assert args.func(args) == 0
    assert browser == ["https://auth.example/work?x=1"]
