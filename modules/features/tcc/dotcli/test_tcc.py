import sqlite3
import sys
import textwrap

import pytest

from dotcli.lib import DotcliError
from dotcli.plugins import tcc

# A requirement blob is its own text here, and the fake codesign reads a
# bundle's designated requirement from <bundle>/DR.
FAKE_CSREQ = textwrap.dedent(
    """\
    import sys
    print(open(sys.argv[2]).read())
    """
)
FAKE_CODESIGN = textwrap.dedent(
    """\
    import sys
    from pathlib import Path
    print("Executable=whatever")
    print("designated => " + (Path(sys.argv[-1]) / "DR").read_text())
    """
)

CLIENT = "com.example.wm"


def script(path, body):
    path.write_text(f"#!{sys.executable}\n" + body)
    path.chmod(0o755)
    return str(path)


def make_db(path, rows=()):
    con = sqlite3.connect(path)
    con.execute("create table access (service, client, client_type, auth_value, csreq)")
    con.executemany("insert into access values (?, ?, 0, ?, ?)", rows)
    con.commit()
    con.close()
    return str(path)


@pytest.fixture
def bundle(tmp_path):
    app = tmp_path / "WM.app"
    (app / "Contents" / "MacOS").mkdir(parents=True)
    exe = app / "Contents" / "MacOS" / "wm"
    exe.touch()
    (app / "DR").write_text(f'identifier "{CLIENT}"')
    link = tmp_path / "bin-wm"
    link.symlink_to(exe)
    return app, link


@pytest.fixture
def settings(tmp_path, bundle):
    _, link = bundle
    return {
        "databases": [make_db(tmp_path / "user.db"), make_db(tmp_path / "system.db")],
        "grants": {CLIENT: {"executable": str(link), "services": ["Accessibility"]}},
        "codesign": script(tmp_path / "codesign", FAKE_CODESIGN),
        "csreq": script(tmp_path / "csreq", FAKE_CSREQ),
    }


def grant_in(settings, db_index, auth=2, req=f'identifier "{CLIENT}"'):
    con = sqlite3.connect(settings["databases"][db_index])
    con.execute(
        "insert into access values ('kTCCServiceAccessibility', ?, 0, ?, ?)",
        (CLIENT, auth, req.encode() if req else None),
    )
    con.commit()
    con.close()


def only_check(settings):
    [check] = tcc.doctor(settings)
    return check


def test_doctor_accepts_a_grant_in_the_system_database(settings):
    grant_in(settings, 1)

    assert only_check(settings).ok


def test_doctor_reports_a_missing_grant(settings):
    check = only_check(settings)
    assert not check.ok
    assert "not granted" in check.hint


def test_doctor_reports_a_denied_grant(settings):
    grant_in(settings, 1, auth=0)

    assert "not granted" in only_check(settings).hint


def test_doctor_reports_a_grant_bound_to_an_older_signature(settings):
    grant_in(settings, 1, req='cdhash H"0123"')

    check = only_check(settings)
    assert not check.ok
    assert "older signature" in check.hint


def test_doctor_reports_an_unreadable_database(settings, tmp_path):
    (tmp_path / "locked.db").write_text("not a database")
    settings["databases"] = [str(tmp_path / "locked.db")]

    check = only_check(settings)
    assert check.label == "TCC database readable"
    assert not check.ok


def test_grant_is_a_noop_when_everything_is_granted(settings, monkeypatch):
    grant_in(settings, 0)
    monkeypatch.setattr("builtins.input", lambda _: pytest.fail("prompted"))

    assert tcc.grant(settings) == 0


def test_grant_opens_the_pane_and_reveals_the_bundle(settings, bundle, monkeypatch):
    app, _ = bundle
    opened = []
    monkeypatch.setattr(tcc, "macos_open", lambda *args: opened.append(list(args)))
    monkeypatch.setattr("builtins.input", lambda _: grant_in(settings, 1))

    assert tcc.grant(settings) == 0
    assert opened == [
        ["x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"],
        ["-R", str(app.resolve())],
    ]


def test_grant_fails_when_the_permission_is_still_missing(settings, monkeypatch):
    monkeypatch.setattr(tcc, "macos_open", lambda *args: None)
    monkeypatch.setattr("builtins.input", lambda _: None)

    assert tcc.grant(settings) == 1


def test_an_executable_outside_a_bundle_is_an_error(settings, tmp_path):
    (tmp_path / "loose").touch()
    settings["grants"][CLIENT]["executable"] = str(tmp_path / "loose")
    grant_in(settings, 1)

    with pytest.raises(DotcliError, match="not inside an .app bundle"):
        list(tcc.doctor(settings))
