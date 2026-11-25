import json
import os
import sys
import textwrap

import pytest

from dotcli.lib import DotcliError
from dotcli.plugins import gh

# The fake keeps the logged-in user in <GH_CONFIG_DIR>/user, and `auth login`
# authorizes whoever <bin>/browser-user names, as a real browser session would.
FAKE_GH = textwrap.dedent(
    """\
    import json
    import os
    import sys
    from pathlib import Path

    here = Path(sys.argv[0]).parent
    conf = Path(os.environ["GH_CONFIG_DIR"])
    args = sys.argv[1:]
    with open(here / "calls", "a") as f:
        f.write(json.dumps([conf.name] + args) + "\\n")
    if args[:2] == ["auth", "status"]:
        user = conf / "user"
        hosts = {}
        if user.exists():
            hosts["github.com"] = [
                {"state": "success", "active": True, "login": user.read_text()}
            ]
        print(json.dumps({"hosts": hosts}))
    elif args[:2] == ["auth", "login"]:
        if (here / "fail-login").exists():
            sys.exit(1)
        conf.mkdir(exist_ok=True)
        (conf / "user").write_text((here / "browser-user").read_text())
    """
)


@pytest.fixture
def bindir(tmp_path):
    d = tmp_path / "bin"
    d.mkdir()
    exe = d / "gh"
    exe.write_text(f"#!{sys.executable}\n" + FAKE_GH)
    exe.chmod(0o755)
    return d


@pytest.fixture
def settings(tmp_path, bindir):
    return {
        "gh": str(bindir / "gh"),
        "host": "github.com",
        "accounts": {
            "personal": {"configDir": str(tmp_path / "gh"), "user": "me"},
            "work": {
                "configDir": str(tmp_path / "gh-work"),
                "user": "me-work",
                "scopes": ["read:packages", "workflow"],
            },
        },
    }


def logged_in_as(settings, name, user):
    conf = settings["accounts"][name]["configDir"]
    os.makedirs(conf, exist_ok=True)
    with open(os.path.join(conf, "user"), "w") as f:
        f.write(user)


def browser_as(bindir, user):
    (bindir / "browser-user").write_text(user)


def login_calls(bindir):
    lines = (bindir / "calls").read_text().splitlines()
    return [c for c in map(json.loads, lines) if c[1:3] == ["auth", "login"]]


def test_login_logs_in_only_accounts_without_a_session(settings, bindir):
    logged_in_as(settings, "personal", "me")
    browser_as(bindir, "me-work")

    assert gh.login([], settings) == 0
    [call] = login_calls(bindir)
    assert call[0] == "gh-work"


def test_login_requests_the_configured_scopes(settings, bindir):
    browser_as(bindir, "me-work")

    gh.login(["work"], settings)
    [call] = login_calls(bindir)
    assert call[call.index("--scopes") + 1] == "read:packages,workflow"


def test_login_rejects_a_token_for_the_browsers_other_account(settings, bindir):
    browser_as(bindir, "me")

    with pytest.raises(DotcliError, match="authorized as me, expected me-work"):
        gh.login(["work"], settings)


def test_login_refuses_to_overwrite_a_session_for_another_user(settings, bindir):
    logged_in_as(settings, "work", "me")
    browser_as(bindir, "me-work")

    with pytest.raises(DotcliError, match="logged in as me, expected me-work"):
        gh.login(["work"], settings)
    assert login_calls(bindir) == []


def test_login_fails_when_gh_fails(settings, bindir):
    browser_as(bindir, "me")
    (bindir / "fail-login").touch()

    with pytest.raises(DotcliError, match="`gh auth login` failed"):
        gh.login(["personal"], settings)


def test_login_rejects_unknown_accounts(settings):
    with pytest.raises(DotcliError, match="unknown account"):
        gh.login(["nope"], settings)


def test_doctor_reports_each_account(settings):
    logged_in_as(settings, "personal", "me")
    logged_in_as(settings, "work", "me")

    checks = {c.label: c for c in gh.doctor(settings)}
    assert checks["gh (personal) logged in as me"].ok
    work = checks["gh (work) logged in as me-work"]
    assert not work.ok
    assert "logged in as me" in work.hint
