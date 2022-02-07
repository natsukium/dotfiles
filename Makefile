.PHONY: install_nix install_nix_unstable install_home_manager uninstall_nix

UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
	NIX_PROFILE := $(HOME)/.nix-profile/etc/profile.d/nix.sh
else
	NIX_PROFILE := /nix/var/nix/profiles/default/etc/profile.d/nix.sh
endif

minimum: install_nix install_nix_unstable install_home_manager

$(NIX_PROFILE):
	. $(PWD)/bin/install_nix.sh && install_nix

install_nix: $(NIX_PROFILE)

install_nix_unstable: $(NIX_PROFILE)
	. $^ && . $(PWD)/bin/install_nix.sh && install_nix_unstable

install_home_manager: $(NIX_PROFILE)
	. $^ && . $(PWD)/bin/install_nix.sh && install_home_manager

uninstall_nix:
	. $(PWD)/bin/install_nix.sh && uninstall_nix

container: bin/remote-container.sh
	$(PWD)/bin/remote-container.sh
