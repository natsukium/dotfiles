.PHONY: build build-all x86_64-linux aarch64-linux aarch64-darwin tangle

# org-babel tangle
EMACS := emacs --batch -l org --eval '(setq org-src-preserve-indentation t)'

define tangle-org
	$(EMACS) --eval '(org-babel-tangle-file "$(1)")'
endef

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
		.#devShells.x86_64-linux.default \

aarch64-linux:
	$(NIX) build --impure --keep-going --no-link --show-trace --eval-system aarch64-linux \
		.#nixosConfigurations.serengeti.config.system.build.toplevel \
		.#nixOnDroidConfigurations.default.config.environment.path \
		.#devShells.aarch64-linux.default \

aarch64-darwin:
	$(NIX) build --keep-going --no-link --show-trace --eval-system aarch64-darwin --option extra-sandbox-paths /nix/store \
		.#darwinConfigurations.katavi.system \
		.#darwinConfigurations.mikumi.system \
		.#darwinConfigurations.work.system \
		.#devShells.aarch64-darwin.default \

# tangle targets: configuration.org -> generated files
# Each directory has a configuration.org that tangles to one or more .nix files
tangle: overlays/default.nix

overlays/default.nix: overlays/configuration.org
	$(call tangle-org,$<)

CLAUDE.md: README.org
	$(EMACS) -l ox-md \
	  --visit $< \
	  --eval '(re-search-forward "^\\* Philosophy")' \
	  --eval '(org-md-export-to-markdown nil t)'
