{
  lib,
  fastfetch,
  makeWrapper,
  runCommandNoCC,
}:

runCommandNoCC "my-fastfetch" { nativeBuildInputs = [ makeWrapper ]; } ''
  makeWrapper ${lib.getExe fastfetch} $out/bin/fastfetch --add-flags "-c ${./config.jsonc}"
''
