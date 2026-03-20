.PHONY: build build-all x86_64-linux aarch64-linux aarch64-darwin tangle

#──────────────────────────────────────────────
# Org-babel tangle
#──────────────────────────────────────────────

EMACS := emacs --batch -l org --eval '(setq org-src-preserve-indentation t org-resource-download-policy t)'

define tangle-org
	$(EMACS) --eval '(dolist (file (org-babel-tangle-file "$(1)")) (with-current-buffer (find-file-noselect file) (delete-trailing-whitespace) (save-buffer)))'
endef

tangle-targets = $(shell grep -oE ':tangle [^ :]+' $(1) | sed 's/:tangle //' | grep -v '^no$$' | sed 's|^\.\./||' | sort -u)

CONF_TANGLE        := $(call tangle-targets,docs/configuration.org)
NIX_TANGLE         := $(call tangle-targets,docs/nix.org)
NETWORKING_TANGLE  := $(call tangle-targets,docs/networking.org)
SHELL_TANGLE       := $(call tangle-targets,docs/shell.org)
VCS_TANGLE         := $(call tangle-targets,docs/vcs.org)
BROWSER_TANGLE     := $(call tangle-targets,docs/browser.org)
OVERLAYS_TANGLE    := $(call tangle-targets,docs/overlays.org)

tangle: $(CONF_TANGLE) $(NIX_TANGLE) $(NETWORKING_TANGLE) $(SHELL_TANGLE) $(VCS_TANGLE) $(BROWSER_TANGLE) $(OVERLAYS_TANGLE) CLAUDE.md .github/README.org

# org-babel skips writing files whose content is unchanged, leaving their mtime
# stale and causing make to re-tangle on every invocation.
$(CONF_TANGLE) &: docs/configuration.org
	$(call tangle-org,$<)
	@touch $(CONF_TANGLE)

$(NIX_TANGLE) &: docs/nix.org
	$(call tangle-org,$<)

$(NETWORKING_TANGLE) &: docs/networking.org
	$(call tangle-org,$<)

$(SHELL_TANGLE) &: docs/shell.org
	$(call tangle-org,$<)

$(VCS_TANGLE) &: docs/vcs.org
	$(call tangle-org,$<)

$(BROWSER_TANGLE) &: docs/browser.org
	$(call tangle-org,$<)

$(OVERLAYS_TANGLE) &: docs/overlays.org
	$(call tangle-org,$<)

CLAUDE.md: docs/configuration.org scripts/export-claude-md.el
	$(EMACS) --visit $< -l $(CURDIR)/scripts/export-claude-md.el

.github/README.org: docs/configuration.org scripts/export-readme-org.el
	@mkdir -p .github
	$(EMACS) --visit $< --eval '(setq export-readme-dest "$(CURDIR)/$@")' -l $(CURDIR)/scripts/export-readme-org.el

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
