{
  pkgs ? import <nixpkgs> { },
  nurpkgs ? import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz"
    ) { inherit pkgs; },
}:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    nurpkgs.repos.natsukium.nixfmt
    pandoc
    shellcheck
    shfmt
    sops
    ssh-to-age
  ];
  shellHook = "";
}
