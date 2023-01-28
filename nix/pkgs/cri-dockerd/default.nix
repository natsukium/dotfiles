{
  fetchFromGitHub,
  buildGoModule,
  cni-plugins,
  ...
}:
buildGoModule rec {
  pname = "cri-dockerd";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "Mirantis";
    repo = "cri-dockerd";
    rev = "v${version}";
    sha256 = "kjHSws47t5NinlgVBtdJlyf+3aB0f2payDXloXyTehY=";
  };
  vendorHash = null;

  postPatch = ''
    sed -i -e 's|/opt/cni/bin|${cni-plugins}/bin|g' cmd/cri/options/options.go
    sed -i -e 's|/opt/cni/bin|${cni-plugins}/bin|g' network/kubenet/kubenet_linux.go
  '';

  postInstall = ''
    install -D $src/packaging/systemd/* -t $out/systemd/system
  '';

  doCheck = false;
}
