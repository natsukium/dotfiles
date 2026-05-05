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

buildPythonPackage rec {
  pname = "pypetkitapi";
  version = "1.26.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Jezza34000";
    repo = "py-petkit-api";
    tag = version;
    hash = "sha256-u4o6Uf4hBXDHFTAgftByT0V7tlhiMKRUvlGicHRVB+s=";
  };

  build-system = [ poetry-core ];

  # upstream pins aiofiles<25.0.0 but nixpkgs ships 25.x;
  # the API is unchanged, so relaxing is safe.
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
    changelog = "https://github.com/Jezza34000/py-petkit-api/releases/tag/${version}";
    license = lib.licenses.mit;
  };
}
