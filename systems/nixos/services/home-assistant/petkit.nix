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
  version = "1.27.0";

  src = fetchFromGitHub {
    inherit owner;
    repo = "homeassistant_petkit";
    tag = version;
    hash = "sha256-pK3/JwtQSq91TlO4W0GoUq5i/1VsDuH0K6S3KYfyARI=";
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
