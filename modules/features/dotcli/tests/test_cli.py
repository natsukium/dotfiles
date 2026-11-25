import json
import sys
import types

import pytest
from dotcli import cli
from dotcli.lib import Check, DotcliError, service_command


@pytest.fixture
def fake_plugin(monkeypatch):
    module = types.ModuleType("dotcli.plugins.fake")
    module.HELP = "fake plugin"
    module.calls = []

    def register(parser, settings):
        actions = parser.add_subparsers(dest="action", required=True)
        run = actions.add_parser("run")
        run.add_argument("--flag", action="store_true")
        run.set_defaults(func=lambda args: module.run(args, settings))

    def run(args, settings):
        module.calls.append((args.flag, settings))
        return settings.get("exit", 0)

    def doctor(settings):
        yield Check("first", True, "hint for first")
        yield Check("second", settings.get("healthy", True), "hint for second")

    module.register = register
    module.run = run
    module.doctor = doctor
    monkeypatch.setitem(sys.modules, "dotcli.plugins.fake", module)
    return module


def write_config(tmp_path, settings):
    path = tmp_path / "plugins.json"
    path.write_text(json.dumps({"fake": settings}))
    return path


def test_plugin_action_receives_its_settings_and_arguments(tmp_path, fake_plugin):
    config = write_config(tmp_path, {"key": "value"})

    assert cli.main(config, ["fake", "run", "--flag"]) == 0
    assert fake_plugin.calls == [(True, {"key": "value"})]


def test_plugin_action_exit_code_is_propagated(tmp_path, fake_plugin):
    config = write_config(tmp_path, {"exit": 1})

    assert cli.main(config, ["fake", "run"]) == 1


@pytest.mark.parametrize("argv", [["missing"], ["fake"], ["fake", "missing"]])
def test_unknown_plugin_or_missing_action_is_a_usage_error(tmp_path, fake_plugin, argv):
    config = write_config(tmp_path, {})

    with pytest.raises(SystemExit) as e:
        cli.main(config, argv)
    assert e.value.code == 2


def test_doctor_succeeds_when_every_check_passes(tmp_path, fake_plugin, capsys):
    config = write_config(tmp_path, {"healthy": True})

    assert cli.main(config, ["doctor"]) == 0
    out = capsys.readouterr().out
    assert "[ok] first" in out
    assert "[ok] second" in out
    assert "hint" not in out


def test_doctor_fails_and_shows_hint_only_for_failed_checks(tmp_path, fake_plugin, capsys):
    config = write_config(tmp_path, {"healthy": False})

    assert cli.main(config, ["doctor"]) == 1
    out = capsys.readouterr().out
    assert "[NG] second  (hint for second)" in out
    assert "hint for first" not in out


def test_dotcli_error_becomes_exit_code_one_with_message(tmp_path, fake_plugin, capsys):
    def failing_run(args, settings):
        raise DotcliError("boom")

    fake_plugin.run = failing_run
    config = write_config(tmp_path, {})

    assert cli.main(config, ["fake", "run"]) == 1
    assert "error: boom" in capsys.readouterr().err


def test_service_command_targets_home_manager_launchd_label_on_darwin():
    cmd = service_command("pizauth", platform="darwin")

    assert cmd[:3] == ["launchctl", "kickstart", "-k"]
    assert cmd[3].endswith("/org.nix-community.home.pizauth")


def test_service_command_targets_systemd_user_unit_on_linux():
    assert service_command("pizauth", platform="linux") == [
        "systemctl",
        "--user",
        "restart",
        "pizauth.service",
    ]
