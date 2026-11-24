import json
import sys
import types

import pytest
from dots import cli
from dots.lib import Check, DotsError, service_command


@pytest.fixture
def fake_plugin(monkeypatch):
    module = types.ModuleType("dots.plugins.fake")
    module.HELP = "fake plugin"
    module.calls = []

    def add_arguments(parser):
        parser.add_argument("--flag", action="store_true")

    def new(args, settings):
        module.calls.append((args.flag, settings))
        return settings.get("exit", 0)

    def doctor(settings):
        yield Check("first", True, "hint for first")
        yield Check("second", settings.get("healthy", True), "hint for second")

    module.add_arguments = add_arguments
    module.new = new
    module.doctor = doctor
    monkeypatch.setitem(sys.modules, "dots.plugins.fake", module)
    return module


def write_config(tmp_path, settings):
    path = tmp_path / "plugins.json"
    path.write_text(json.dumps({"fake": settings}))
    return path


def test_new_dispatches_to_plugin_with_its_settings_and_arguments(tmp_path, fake_plugin):
    config = write_config(tmp_path, {"key": "value"})

    assert cli.main(config, ["new", "fake", "--flag"]) == 0
    assert fake_plugin.calls == [(True, {"key": "value"})]


def test_new_propagates_plugin_exit_code(tmp_path, fake_plugin):
    config = write_config(tmp_path, {"exit": 1})

    assert cli.main(config, ["new", "fake"]) == 1


def test_unknown_plugin_is_a_usage_error(tmp_path, fake_plugin):
    config = write_config(tmp_path, {})

    with pytest.raises(SystemExit) as e:
        cli.main(config, ["new", "missing"])
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


def test_dots_error_becomes_exit_code_one_with_message(tmp_path, fake_plugin, capsys):
    def failing_new(args, settings):
        raise DotsError("boom")

    fake_plugin.new = failing_new
    config = write_config(tmp_path, {})

    assert cli.main(config, ["new", "fake"]) == 1
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
