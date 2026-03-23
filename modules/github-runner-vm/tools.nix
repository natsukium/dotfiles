# Packages available in the GitHub Actions runner environment.
# Mirrors the tool set of GitHub-hosted runners (ubuntu-latest).
pkgs: with pkgs; [
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
]
