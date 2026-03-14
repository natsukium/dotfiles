.PHONY: build build-all x86_64-linux aarch64-linux aarch64-darwin tangle

# org-babel tangle
EMACS := emacs --batch -l org --eval '(setq org-src-preserve-indentation t org-resource-download-policy t)'

define tangle-org
	$(EMACS) --eval '(dolist (file (org-babel-tangle-file "$(1)")) (with-current-buffer (find-file-noselect file) (delete-trailing-whitespace) (save-buffer)))'
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
	$(NIX) build --keep-going --no-link --show-trace --eval-system x86_64-linux --print-out-paths \
		.#nixosConfigurations.arusha.config.system.build.toplevel \
		.#nixosConfigurations.kilimanjaro.config.system.build.toplevel \
		.#nixosConfigurations.manyara.config.system.build.toplevel \
		.#devShells.x86_64-linux.default \

aarch64-linux:
	$(NIX) build --keep-going --no-link --show-trace --eval-system aarch64-linux --print-out-paths \
		.#nixosConfigurations.serengeti.config.system.build.toplevel \
		.#nixOnDroidConfigurations.default.config.environment.path \
		.#devShells.aarch64-linux.default \

aarch64-darwin:
	$(NIX) build --keep-going --no-link --show-trace --eval-system aarch64-darwin --print-out-paths \
		.#darwinConfigurations.katavi.system \
		.#darwinConfigurations.mikumi.system \
		.#darwinConfigurations.work.system \
		.#devShells.aarch64-darwin.default \

# tangle targets: configuration.org -> generated files
# Each directory has a configuration.org that tangles to one or more .nix files
tangle: flake.nix overlays/default.nix modules/nixos/tailscale.nix modules/home/development/git/default.nix modules/home/zen-browser/default.nix modules/shared/nix/default.nix modules/shared/nixpkgs/default.nix modules/shared/nix/build-machines.nix modules/home/nix/default.nix .github/README.org CLAUDE.md po4a.cfg scripts/org-to-html.el scripts/check-po4a.sh scripts/check-org-tangle.sh scripts/check-git-changes.sh scripts/export-claude-md.el scripts/export-readme-org.el

CONF_TANGLE := flake.nix po4a.cfg scripts/org-to-html.el scripts/check-po4a.sh scripts/check-org-tangle.sh scripts/check-git-changes.sh scripts/export-claude-md.el scripts/export-readme-org.el

# org-babel skips writing files whose content is unchanged, leaving their mtime
# stale and causing make to re-tangle on every invocation.
$(CONF_TANGLE) &: configuration.org
	$(call tangle-org,$<)
	@touch $(CONF_TANGLE)

overlays/default.nix &: overlays/configuration.org
	$(call tangle-org,$<)

modules/nixos/tailscale.nix modules/home/development/git/default.nix modules/home/zen-browser/default.nix modules/shared/nix/default.nix modules/shared/nixpkgs/default.nix modules/shared/nix/build-machines.nix modules/home/nix/default.nix &: modules/configuration.org
	$(call tangle-org,$<)

CLAUDE.md: configuration.org scripts/export-claude-md.el
	$(EMACS) --visit $< -l scripts/export-claude-md.el

.github/README.org: configuration.org scripts/export-readme-org.el
	@mkdir -p .github
	$(EMACS) --visit $< --eval '(setq export-readme-dest "$@")' -l scripts/export-readme-org.el
