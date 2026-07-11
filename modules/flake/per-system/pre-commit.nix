{ inputs, ... }:
{
  imports = [ inputs.git-hooks.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      pre-commit = {
        check.enable = true;
        settings = {
          package = pkgs.prek;
          src = ../../..;
          hooks =
            let
              check-git-changes = pkgs.writeShellApplication {
                name = "check-git-changes";
                runtimeInputs = [ pkgs.git ];
                text = builtins.readFile ../../../scripts/check-git-changes.sh;
              };
              emacs-with-org = (pkgs.emacsPackagesFor pkgs.emacs).emacsWithPackages (epkgs: [ epkgs.org ]);
            in
            {
              actionlint = {
                enable = true;
                priority = 10;
              };
              biome = {
                enable = true;
                priority = 10;
              };
              lua-ls = {
                enable = false;
                priority = 10;
              };
              nil = {
                enable = true;
                priority = 10;
              };
              shellcheck = {
                enable = true;
                priority = 10;
              };
              treefmt = {
                enable = true;
                priority = 10;
              };
              typos = {
                enable = true;
                priority = 10;
                excludes = [
                  ".sops.yaml"
                  "homes/shared/gpg/keys.txt"
                  "secrets.yaml"
                  "secrets/default.yaml"
                  "hosts/nixos/tarangire/facter.json"
                  "systems/shared/hercules-ci/binary-caches.json"
                ];
                settings.configPath = "typos.toml";
              };
              yamllint = {
                enable = true;
                priority = 10;
                excludes = [
                  "secrets/default.yaml"
                  "secrets.yaml"
                ];
                settings.configData = "{rules: {document-start: {present: false}}}";
              };
              po4a = {
                enable = true;
                name = "po4a";
                description = "Update translations with po4a";
                priority = 10;
                entry = pkgs.lib.getExe (
                  pkgs.writeShellApplication {
                    name = "check-po4a";
                    runtimeInputs = [
                      pkgs.po4a
                      pkgs.gettext
                      check-git-changes
                    ];
                    text = builtins.readFile ../../../scripts/check-po4a.sh;
                  }
                );
                files = "(\\.org|po/.*\\.po)$";
                pass_filenames = false;
              };
              "check-org-tangle" = {
                enable = true;
                name = "check-org-tangle";
                description = "Verify org files are tangled and synchronized";
                # Ensure this hook runs before all other hooks
                priority = 0;
                entry = pkgs.lib.getExe (
                  pkgs.writeShellApplication {
                    name = "check-org-tangle";
                    runtimeInputs = [
                      emacs-with-org
                      pkgs.gnumake
                      check-git-changes
                    ];
                    text = builtins.readFile ../../../scripts/check-org-tangle.sh;
                  }
                );
                files = "\\.org$";
                pass_filenames = false;
              };
            };
        };
      };
    };
}
