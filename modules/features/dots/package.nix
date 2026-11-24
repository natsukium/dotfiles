{
  lib,
  age,
  git,
  python3,
  runCommandLocal,
  writeText,
  plugins,
}:
let
  config = writeText "dots-plugins.json" (builtins.toJSON (lib.mapAttrs (_: p: p.settings) plugins));

  installPlugins = lib.concatStrings (
    lib.mapAttrsToList (name: p: ''
      cp ${p.source} $lib/dots/plugins/${name}.py
    '') plugins
  );

  copyTests = lib.concatStrings (
    lib.mapAttrsToList (
      name: p:
      lib.optionalString (p.tests != null) ''
        cp ${p.tests} tests/test_${name}.py
      ''
    ) plugins
  );
in
runCommandLocal "dots"
  {
    nativeBuildInputs = [
      age
      git
      (python3.withPackages (ps: [ ps.pytest ]))
    ];
    meta.mainProgram = "dots";
  }
  ''
    lib=$out/lib/dots
    mkdir -p $lib $out/bin
    cp -r --no-preserve=mode ${./dots} $lib/dots
    ${installPlugins}

    cat > $out/bin/dots <<EOF
    #!${python3.interpreter} -I
    import sys
    sys.path.insert(0, "$lib")
    from dots.cli import main
    sys.exit(main("${config}"))
    EOF
    chmod +x $out/bin/dots

    mkdir tests
    cp ${./tests}/*.py tests/
    ${copyTests}
    HOME=$TMPDIR PYTHONPATH=$lib python -m pytest -q -p no:cacheprovider tests
    find $lib -name __pycache__ -exec rm -rf {} +
  ''
