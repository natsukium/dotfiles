#!/usr/bin/env bash

mkdir -p persistent/etc/ssh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

umask 0177
# put the ssh auth key in the persist directory or it cannot be accessed at boot time
# https://github.com/Mic92/sops-nix/blob/99b1e37f9fc0960d064a7862eb7adfb92e64fa10/README.md?plain=1#L594-L596
sops --extract '["ssh_host_ed25519_key"]' -d "$SCRIPT_DIR/../nix/systems/nixos/serengeti/secrets.yaml" >./persistent/etc/ssh/ssh_host_ed25519_key
