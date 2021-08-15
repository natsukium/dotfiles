.PHONY: install_nix install_nix_unstable install_home_manager uninstall_nix

minimum: install_nix install_nix_unstable install_home_manager

install_nix:
	. $(PWD)/bin/install_nix.sh
	install_nix

install_nix_unstable:
	. $(PWD)/bin/install_nix.sh
	install_nix_unstable

install_home_manager:
	. $(PWD)/bin/install_nix.sh
	install_home_manager

uninstall_nix:
	. $(PWD)/bin/install_nix.sh
	uninstall_nix

container: bin/remote-container.sh
	$(PWD)/bin/remote-container.sh
