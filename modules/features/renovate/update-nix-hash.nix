{
  lib,
  makeBinaryWrapper,
  nix,
  python3,
  runCommandLocal,
}:
runCommandLocal "update-nix-hash"
  {
    nativeBuildInputs = [
      makeBinaryWrapper
      python3
    ];

    passthru.tests.pytest =
      runCommandLocal "update-nix-hash-tests"
        {
          nativeBuildInputs = [ (python3.withPackages (ps: [ ps.pytest ])) ];
        }
        ''
          cp ${./update_nix_hash.py} update_nix_hash.py
          cp ${./test_update_nix_hash.py} test_update_nix_hash.py
          pytest -q
          touch $out
        '';

    meta.mainProgram = "update-nix-hash";
  }
  ''
    install -Dm755 ${./update_nix_hash.py} $out/bin/update-nix-hash
    patchShebangs $out/bin
    wrapProgram $out/bin/update-nix-hash --prefix PATH : ${lib.makeBinPath [ nix ]}
  ''
