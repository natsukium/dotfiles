{
  pkgs ? import <nixpkgs> {
    config = {
      allowUnfree = true;
    };
    overlays = builtins.attrValues (
      (import (builtins.fetchTarball "https://github.com/natsukium/nur-packages/archive/main.tar.gz") { })
      .overlays
    );
  },
}:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    nixfmt
    pandoc
    shellcheck
    shfmt
    sops
    ssh-to-age
    (terraform.withPlugins (p: [
      p.external
      p.null
      p.oci
      p.sops
    ]))
  ];
  shellHook = "";
}
