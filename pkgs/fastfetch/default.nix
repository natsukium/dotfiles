{
  lib,
  fastfetch,
  makeWrapper,
  runCommand,
}:

runCommand "my-fastfetch" { nativeBuildInputs = [ makeWrapper ]; } ''
  makeWrapper ${lib.getExe fastfetch} $out/bin/fastfetch --add-flags "-c ${./config.jsonc}"
''
