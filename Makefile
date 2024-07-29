.PHONY: install_nix uninstall_nix switch setup build build-all x86_64-linux aarch64-linux aarch64-darwin

UNAME := $(shell uname)
NIX_PROFILE := /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

NIX := nom

OS := $(shell uname -s)
ARCH := $(shell uname -m)

JOBS_X86_64-LINUX :=
JOBS_AARCH64-LINUX :=
JOBS_AARCH64-DARWIN :=

ifeq ($(OS),Linux)
	JOBS_AARCH64-DARWIN := -j0
	ifeq ($(ARCH),x86_64)
		SYSTEM := x86_64-linux
		JOBS_AARCH64-LINUX := -j0
	else ifeq ($(ARCH),aarch64)
		SYSTEM := aarch64-linux
		JOBS_X86_64-LINUX := -j0
	endif
else ifeq ($(OS),Darwin)
	SYSTEM := aarch64-darwin
	JOBS_X86_64-LINUX := -j0
	JOBS_AARCH64-LINUX := -j0
endif

build: $(SYSTEM)

build-all: x86_64-linux aarch64-linux aarch64-darwin

x86_64-linux:
	$(NIX) build --impure --no-link --show-trace --system x86_64-linux $(JOBS_X86_64-LINUX) \
		.#nixosConfigurations.arusha.config.system.build.toplevel \
		.#nixosConfigurations.kilimanjaro.config.system.build.toplevel \
		.#nixosConfigurations.manyara.config.system.build.toplevel \

aarch64-linux:
	$(NIX) build --impure --no-link --show-trace --system aarch64-linux $(JOBS_AARCH64-LINUX) \
		.#nixosConfigurations.serengeti.config.system.build.toplevel \

aarch64-darwin:
	$(NIX) build --no-link --show-trace --system aarch64-darwin $(JOBS_AARCH64-DARWIN) \
		.#darwinConfigurations.katavi.system \
		.#darwinConfigurations.mikumi.system \
		.#darwinConfigurations.work.system \

minimum: install_nix switch

$(NIX_PROFILE):
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

install_nix: $(NIX_PROFILE)

switch: nix/home.nix
	home-manager -f nix/home.nix switch -b backup

uninstall_nix:
	/nix/nix-installer uninstall
