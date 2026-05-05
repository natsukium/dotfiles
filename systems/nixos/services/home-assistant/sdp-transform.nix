{
  lib,
  buildPythonPackage,
  fetchPypi,
  poetry-core,
}:

buildPythonPackage rec {
  pname = "sdp-transform";
  version = "1.1.0";
  pyproject = true;

  src = fetchPypi {
    pname = "sdp_transform";
    inherit version;
    hash = "sha256-Qi4JdTqFUJbrkVuIZ2CP8Koaw6x548nHWPbs/eFUiq0=";
  };

  build-system = [ poetry-core ];

  pythonImportsCheck = [ "sdp_transform" ];

  meta = {
    description = "Simple Python parser and writer of SDP";
    homepage = "https://pypi.org/project/sdp-transform/";
    license = lib.licenses.mit;
  };
}
