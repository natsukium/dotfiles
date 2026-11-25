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
  config = writeText "dotcli-plugins.json" (
    builtins.toJSON (lib.mapAttrs (_: p: p.settings) plugins)
  );

  installPlugins = lib.concatStrings (
    lib.mapAttrsToList (name: p: ''
      cp -r --no-preserve=mode ${p.source} $lib/dotcli/plugins/${name}
    '') plugins
  );
in
runCommandLocal "dotcli"
  {
    nativeBuildInputs = [
      age
      git
      (python3.withPackages (ps: [ ps.pytest ]))
    ];
    meta.mainProgram = "dotcli";
  }
  ''
    lib=$out/lib/dotcli
    mkdir -p $lib $out/bin
    cp -r --no-preserve=mode ${./dotcli} $lib/dotcli
    ${installPlugins}

    cat > $out/bin/dotcli <<EOF
    #!${python3.interpreter} -I
    import sys
    sys.path.insert(0, "$lib")
    from dotcli.cli import main
    sys.exit(main("${config}"))
    EOF
    chmod +x $out/bin/dotcli

    cp -r --no-preserve=mode ${./tests} tests
    HOME=$TMPDIR PYTHONPATH=$lib python -m pytest -q -p no:cacheprovider \
      --rootdir=$out tests $lib/dotcli/plugins
    find $lib/dotcli/plugins -name 'test_*.py' -delete
    find $lib -name __pycache__ -exec rm -rf {} +
  ''
