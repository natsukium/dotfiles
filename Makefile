.PHONY: build build-all x86_64-linux aarch64-linux aarch64-darwin

NIX := nom

OS := $(shell uname -s)
ARCH := $(shell uname -m)

ifeq ($(OS),Linux)
  ifeq ($(ARCH),x86_64)
    SYSTEM := x86_64-linux
  else ifeq ($(ARCH),aarch64)
    SYSTEM := aarch64-linux
  endif
else ifeq ($(OS),Darwin)
	SYSTEM := aarch64-darwin
endif

build: $(SYSTEM)

build-all: x86_64-linux aarch64-linux aarch64-darwin

x86_64-linux:
	$(NIX) build --impure --keep-going --no-link --show-trace --eval-system x86_64-linux \
		.#nixosConfigurations.arusha.config.system.build.toplevel \
		.#nixosConfigurations.kilimanjaro.config.system.build.toplevel \
		.#nixosConfigurations.manyara.config.system.build.toplevel \

aarch64-linux:
	$(NIX) build --impure --keep-going --no-link --show-trace --eval-system aarch64-linux \
		.#nixosConfigurations.serengeti.config.system.build.toplevel \
		.#nixOnDroidConfigurations.default.config.environment.path

aarch64-darwin:
	$(NIX) build --keep-going --no-link --show-trace --eval-system aarch64-darwin --option extra-sandbox-paths /nix/store \
		.#darwinConfigurations.katavi.system \
		.#darwinConfigurations.mikumi.system \
		.#darwinConfigurations.work.system \
