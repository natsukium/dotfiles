{
  pkgs ? import <nixpkgs> {
    config = {
      allowUnfree = true;
    };
  },
  nurpkgs ?
    import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz")
      { inherit pkgs; },
}:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    nurpkgs.repos.natsukium.nixfmt
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
