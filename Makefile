.PHONY: install_nix uninstall_nix switch setup

UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
	NIX_PROFILE := $(HOME)/.nix-profile/etc/profile.d/nix.sh
else
	NIX_PROFILE := /nix/var/nix/profiles/default/etc/profile.d/nix.sh
endif

minimum: install_nix switch

$(NIX_PROFILE):
	. $(PWD)/bin/install_nix.sh && install_nix

install_nix: $(NIX_PROFILE)

switch: nix/home.nix
	home-manager -f nix/home.nix switch -b backup

uninstall_nix:
	. $(PWD)/bin/install_nix.sh && uninstall_nix

container: bin/remote-container.sh
	$(PWD)/bin/remote-container.sh

setup: $(PWD)/.git/hooks

$(PWD)/.git/hooks: $(PWD)/.githooks/*
	ln -sf $^ $@
