{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
  pypetkitapi,
  sdp-transform,
  aiofiles,
  paho-mqtt,
  websockets,
}:

buildHomeAssistantComponent rec {
  owner = "Jezza34000";
  domain = "petkit";
  # renovate: datasource=github-releases depName=Jezza34000/homeassistant_petkit
  version = "1.28.0";

  src = fetchFromGitHub {
    inherit owner;
    repo = "homeassistant_petkit";
    tag = version;
    hash = "sha256-zwjBwE7nHNV9tLQSDh8OqoqBtWl87ysgDuqkvDXrP5E=";
  };

  dependencies = [
    pypetkitapi
    sdp-transform
    aiofiles
    paho-mqtt
    websockets
  ];

  # manifest.json pins exact versions, but nixpkgs already ships compatible newer
  # ones; ignoring lets us reuse the system-wide packages instead of vendoring.
  ignoreVersionRequirement = [
    "aiofiles"
    "websockets"
  ];

  meta = {
    changelog = "https://github.com/Jezza34000/homeassistant_petkit/releases/tag/${version}";
    description = "Home Assistant integration for Petkit devices";
    homepage = "https://github.com/Jezza34000/homeassistant_petkit";
    license = lib.licenses.mit;
  };
}
