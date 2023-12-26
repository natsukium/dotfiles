# Dotfiles

## Install
### for *nix
```sh
sh -c "$(curl -fsSL git.io/dotnatsukium)"
```

### for Windows
```powershell
. { iwr -useb git.io/winnatsukium } | iex
```

### for nix-on-droid
```sh
nix-on-droid switch --flake github:natsukium/dotfiles/develop#default
```

## Nix flake

Build for macbook

```sh
nix build .#darwinConfigurations.macbook.system
darwin-rebuild switch --flake .#macbook
```

Build for linux machine

```sh
nix build --no-link .#homeConfigurations.x64-vm.activationPackage
home-manager switch --flake .#gazelle
```

Update packages

```sh
nix flake update
```
