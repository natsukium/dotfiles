.PHONY: install_nix uninstall_nix switch setup

UNAME := $(shell uname)
NIX_PROFILE := /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

minimum: install_nix switch

$(NIX_PROFILE):
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

install_nix: $(NIX_PROFILE)

switch: nix/home.nix
	home-manager -f nix/home.nix switch -b backup

uninstall_nix:
	/nix/nix-installer uninstall

container: bin/remote-container.sh
	$(PWD)/bin/remote-container.sh

setup: $(PWD)/.git/hooks

$(PWD)/.git/hooks: $(PWD)/.githooks/*
	ln -sf $^ $@
