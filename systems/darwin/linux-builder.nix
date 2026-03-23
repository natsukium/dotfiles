{
  config,
  lib,
  ...
}:
let
  runnerNames = map (n: "natsukium-linux-arm64-${toString n}") (lib.range 1 2);
in
{
  nix.linux-builder = {
    enable = true;
    # github-runners need persistent state for registration and work directories
    ephemeral = false;
    config =
      { pkgs, ... }:
      let
        commonTools = with pkgs; [
          # Core utilities
          acl
          aria2
          autoconf
          automake
          bash
          binutils
          bison
          brotli
          bzip2
          coreutils
          curl
          dbus
          bind # dnsutils
          fakeroot
          file
          findutils
          flex
          fontconfig
          gcc
          stdenv.cc.cc.lib
          gnupg
          gnugrep
          gnused
          gnutar
          haveged
          iproute2
          iputils
          jq
          lz4
          m4
          gnumake
          mediainfo
          mercurial
          netcat
          net-tools
          openssh
          p7zip
          parallel
          patchelf
          pigz
          pkg-config
          python3
          rpm
          rsync
          shellcheck
          sqlite
          sshpass
          sudo
          swig
          tree
          texinfo
          time
          tk
          tzdata
          unzip
          upx
          wget
          xvfb-run
          xz
          zip
          zsync

          # Language and Runtime
          clang
          clang-tools
          dash
          gfortran
          julia
          kotlin
          nodejs
          perl
          python312
          ruby

          # Package Management
          kubernetes-helm
          nodePackages.npm
          python312Packages.pip
          pipx
          yarn

          # Project Management
          ant
          gradle
          maven

          # Tools
          ansible
          awscli2
          bazel_8
          bazelisk
          buildah
          cmake
          docker
          docker-buildx
          docker-compose
          git
          git-lfs
          kind
          kubectl
          kustomize
          openssl
          packer
          podman
          pulumi
          skopeo
          ninja
          yamllint
          yq
          zstd

          # CLI Tools
          azure-cli
          github-cli
          google-cloud-sdk

          # Java
          temurin-jre-bin-8
          temurin-jre-bin-11
          temurin-jre-bin-17
          temurin-jre-bin-21

          # PHP Tools
          php
          phpPackages.composer

          # Haskell Tools
          cabal-install
          ghc
          stack

          # Rust Tools
          cargo
          rustc
          rustfmt

          # Databases
          postgresql
          mysql80

          # Web Servers
          apacheHttpd
          nginx

          # Additional development tools
          cachix
          vim
          gawk
        ];
      in
      {
        # mount the host's decrypted sops secrets into the VM via 9P,
        # avoiding the need for a separate sops-nix setup inside the VM
        virtualisation.sharedDirectories.github-runner-secrets = {
          source = builtins.dirOf config.sops.secrets.github-runner-token.path;
          target = "/var/secrets";
          securityModel = "none";
        };

        nixpkgs.config.allowUnfree = true;
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];

        services.github-runners = lib.genAttrs runnerNames (name: {
          enable = true;
          url = "https://github.com/attmcojp";
          tokenFile = "/var/secrets/${builtins.baseNameOf config.sops.secrets.github-runner-token.path}";
          replace = true;
          extraPackages = commonTools;
          extraLabels = [ "bashauma-linux-arm64" ];
          extraEnvironment = {
            BASH_ENV = "/etc/profile.d/nix-profile.sh";
          };
          workDir = "/var/lib/github-runner-work/${name}";
          user = "github-runner";
          group = "github-runner";
        });

        users.users.github-runner = {
          isSystemUser = true;
          group = "github-runner";
        };
        users.groups.github-runner = { };

        environment.etc."profile.d/nix-profile.sh".text = ''
          export PATH="$HOME/.nix-profile/bin:$PATH"
        '';

        programs.nix-ld.enable = true;

        virtualisation.docker.enable = true;

        systemd.tmpfiles.rules = [
          "d /var/lib/github-runner-work 0755 github-runner github-runner -"
        ]
        ++ map (
          name: "d /var/lib/github-runner-work/${name} 0700 github-runner github-runner -"
        ) runnerNames;

        systemd.services = lib.genAttrs (map (name: "github-runner-${name}") runnerNames) (_: {
          serviceConfig = {
            SupplementaryGroups = [ "docker" ];
          };
        });
      };
  };
}
