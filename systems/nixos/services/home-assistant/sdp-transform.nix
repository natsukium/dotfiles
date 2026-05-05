{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  poetry-core,
}:

buildPythonPackage (finalAttrs: {
  pname = "sdp-transform";
  version = "1.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "skymaze";
    repo = "sdp-transform";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Sr1wCXRLg6GU3JvHSekoxr6vaeI/vAnvb2BI6tjpqEs=";
  };

  build-system = [ poetry-core ];

  pythonImportsCheck = [ "sdp_transform" ];

  meta = {
    description = "Simple Python parser and writer of SDP";
    homepage = "https://pypi.org/project/sdp-transform/";
    changelog = "https://github.com/skymaze/sdp-transform/releases/tag/${finalAttrs.tag}";
    license = lib.licenses.mit;
  };
})
