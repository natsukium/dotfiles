{
  fetchurl,
  python3,
  stdenvNoCC,
  zotero,
}:
let
  # renovate: datasource=github-releases depName=retorquere/zotero-better-bibtex extractVersion=^v(?<version>.+)$
  version = "9.0.70";

  xpi = fetchurl {
    url = "https://github.com/retorquere/zotero-better-bibtex/releases/download/v${version}/zotero-better-bibtex-${version}.xpi";
    hash = "sha256-2v+3hsYoCJLp+oMnCFjzs/q6e/XYODr4UKQ9P9TUhq0=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "zotero-better-bibtex";
  inherit version;

  src = xpi;
  dontUnpack = true;

  doCheck = true;
  nativeCheckInputs = [ python3 ];
  checkPhase = ''
    runHook preCheck
    python3 ${./check-compatibility.py} $src ${version} ${zotero.version}
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -Dm444 $src $out
    runHook postInstall
  '';
}
