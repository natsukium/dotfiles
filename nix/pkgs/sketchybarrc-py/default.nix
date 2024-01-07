{ pkgs, ... }:
with pkgs.python3Packages;
buildPythonPackage rec {
  pname = "sketchybarrc-py";
  version = "0.0.1";

  src = pkgs.fetchFromGitHub {
    owner = "natsukium";
    repo = "sketchybarrc.py";
    rev = "v${version}";
    hash = "sha256-20AMo/7ptKDLiTKupZEVGuZRussMKVw4glLVrx3oqAw=";
  };
  format = "pyproject";
  buildInputs = [ pdm-pep517 ];
  propagatedBuildInputs = [ typing-extensions ];
}
