.PHONY: build build-all x86_64-linux aarch64-linux aarch64-darwin tangle tangle-all

#──────────────────────────────────────────────
# Org-babel tangle
#──────────────────────────────────────────────

# download-policy nil skips the remote #+SETUPFILE fetch (HTML-theme only, irrelevant
# to tangle/export output) so exports don't hit the network on every run.
EMACS := emacs --batch -l org --eval '(setq org-src-preserve-indentation t org-resource-download-policy nil)'

define tangle-org
	$(EMACS) --eval '(dolist (file (org-babel-tangle-file "$(1)")) (with-current-buffer (find-file-noselect file) (delete-trailing-whitespace) (save-buffer)))'
endef

tangle-targets = $(shell grep -oE ':tangle [^ :]+' $(1) | sed 's/:tangle //' | grep -v '^no$$' | sort -u)

CONF_TANGLE    := $(call tangle-targets,configuration.org)
MODULES_TANGLE := $(addprefix modules/,$(call tangle-targets,modules/configuration.org))
OVERLAYS_TANGLE := $(addprefix overlays/,$(call tangle-targets,overlays/configuration.org))

# Each tangle/export target is an independent emacs process; recurse in parallel
tangle:
	@$(MAKE) --no-print-directory -j tangle-all

tangle-all: $(CONF_TANGLE) $(MODULES_TANGLE) $(OVERLAYS_TANGLE) CLAUDE.md .github/README.org

# org-babel skips writing files whose content is unchanged, leaving their mtime
# stale and causing make to re-tangle on every invocation.
$(CONF_TANGLE) &: configuration.org
	$(call tangle-org,$<)
	@touch $(CONF_TANGLE)

$(OVERLAYS_TANGLE) &: overlays/configuration.org
	$(call tangle-org,$<)

$(MODULES_TANGLE) &: modules/configuration.org
	$(call tangle-org,$<)

CLAUDE.md: configuration.org scripts/export-claude-md.el
	$(EMACS) --visit $< -l scripts/export-claude-md.el

.github/README.org: configuration.org scripts/export-readme-org.el
	@mkdir -p .github
	$(EMACS) --visit $< --eval '(setq export-readme-dest "$@")' -l scripts/export-readme-org.el

#──────────────────────────────────────────────
# Nix build
#──────────────────────────────────────────────

NIX := nom

OS   := $(shell uname -s)
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
		.#devShells.x86_64-linux.default

aarch64-linux:
	$(NIX) build --keep-going --no-link --show-trace --eval-system aarch64-linux --print-out-paths \
		.#nixosConfigurations.serengeti.config.system.build.toplevel \
		.#nixOnDroidConfigurations.default.config.environment.path \
		.#devShells.aarch64-linux.default

aarch64-darwin:
	$(NIX) build --keep-going --no-link --show-trace --eval-system aarch64-darwin --print-out-paths \
		.#darwinConfigurations.katavi.system \
		.#darwinConfigurations.mikumi.system \
		.#darwinConfigurations.work.system \
		.#devShells.aarch64-darwin.default
