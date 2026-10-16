{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  poetry-core,
  aiohttp,
  aiofiles,
  pycryptodome,
  m3u8,
  tenacity,
  pydantic,
}:

buildPythonPackage (finalAttrs: {
  pname = "pypetkitapi";
  # renovate: datasource=github-releases depName=Jezza34000/py-petkit-api
  version = "1.31.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Jezza34000";
    repo = "py-petkit-api";
    tag = finalAttrs.version;
    hash = "sha256-Vw5HZTA2+k5GgTlPLp5BmN2AbyZcATdsXsTzBqPea78=";
  };

  build-system = [ poetry-core ];

  pythonRelaxDeps = [ "aiofiles" ];

  dependencies = [
    aiohttp
    aiofiles
    pycryptodome
    m3u8
    tenacity
    pydantic
  ];

  pythonImportsCheck = [ "pypetkitapi" ];

  meta = {
    description = "Python client library for the Petkit API";
    homepage = "https://github.com/Jezza34000/py-petkit-api";
    changelog = "https://github.com/Jezza34000/py-petkit-api/releases/tag/${finalAttrs.version}";
    license = lib.licenses.mit;
  };
})
