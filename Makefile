.PHONY: build build-all x86_64-linux aarch64-linux aarch64-darwin tangle tangle-all

#──────────────────────────────────────────────
# Org-babel tangle
#──────────────────────────────────────────────

# download-policy nil skips the remote #+SETUPFILE fetch (HTML-theme only, irrelevant
# to tangle/export output) so exports don't hit the network on every run.
#
# noweb expansion prefixes every line of the referenced block with the
# indentation of the <<reference>>, blank lines included. Stripping that from
# the block body, rather than from the written file, is what lets org's own
# content comparison match and skip the write. The hook runs per block, so
# delete-trailing-lines has to be off or the newline ending each block goes too.
EMACS := emacs --batch -l org \
	--eval '(setq org-src-preserve-indentation t org-resource-download-policy nil)' \
	--eval '(add-hook (quote org-babel-tangle-body-hook) (lambda () (let ((delete-trailing-lines nil)) (delete-trailing-whitespace))))'

# Stamps stand in as the make targets. org leaves an unchanged file's mtime
# alone, so touching the tangled files to satisfy make would bump flake.nix on
# every run and invalidate the nix-direnv cache on every commit.
STAMPS := .make

define tangle-org
	$(EMACS) --eval '(org-babel-tangle-file "$(1)")'
	@mkdir -p $(@D)
	@touch $@
endef

# Each tangle/export target is an independent emacs process; recurse in parallel
tangle:
	@$(MAKE) --no-print-directory -j tangle-all

tangle-all: $(STAMPS)/configuration $(STAMPS)/modules $(STAMPS)/overlays CLAUDE.md .github/README.org

$(STAMPS)/configuration: configuration.org
	$(call tangle-org,$<)

$(STAMPS)/overlays: overlays/configuration.org
	$(call tangle-org,$<)

$(STAMPS)/modules: modules/configuration.org
	$(call tangle-org,$<)

CLAUDE.md: configuration.org scripts/export-claude-md.el
	$(EMACS) --visit $< -l scripts/export-claude-md.el

.github/README.org: configuration.org scripts/export-readme-org.el
	@mkdir -p .github
	$(EMACS) --visit $< --eval '(setq export-readme-dest "$@")' -l scripts/export-readme-org.el

#──────────────────────────────────────────────
# sops secrets
#──────────────────────────────────────────────

ATTMCOJP_CLAUDE_MD := hosts/darwin/work/attmcojp-claude.md

# Plaintext is kept outside every git repository, so no `git add` anywhere can
# stage it by accident and an agent editing it is never working inside a tree
# that is about to be committed.
SECRET_SCRATCH := $(HOME)/.cache/dotfiles/secrets

.PHONY: attmcojp-claude-md-open attmcojp-claude-md-seal

attmcojp-claude-md-open:
	@mkdir -p $(SECRET_SCRATCH)
	@chmod 700 $(SECRET_SCRATCH)
	@sops decrypt --output $(SECRET_SCRATCH)/attmcojp-claude.md $(ATTMCOJP_CLAUDE_MD)
	@chmod 600 $(SECRET_SCRATCH)/attmcojp-claude.md
	@echo $(SECRET_SCRATCH)/attmcojp-claude.md

# sops edit invokes $EDITOR with the decrypted tempfile as its argument, so cp
# replaces that buffer wholesale. Going through edit rather than a fresh
# `sops encrypt` reuses the existing data key, keeping the ciphertext diff
# confined to the payload instead of rewriting every recipient block per edit.
attmcojp-claude-md-seal:
	@test -f $(SECRET_SCRATCH)/attmcojp-claude.md \
		|| { echo "no plaintext at $(SECRET_SCRATCH)/attmcojp-claude.md; run attmcojp-claude-md-open first" >&2; exit 1; }
	@EDITOR="cp $(SECRET_SCRATCH)/attmcojp-claude.md" sops edit $(ATTMCOJP_CLAUDE_MD)
	@rm -f $(SECRET_SCRATCH)/attmcojp-claude.md

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

ATTRS_x86_64-linux := \
	.\#nixosConfigurations.arusha.config.system.build.toplevel \
	.\#nixosConfigurations.kilimanjaro.config.system.build.toplevel \
	.\#nixosConfigurations.manyara.config.system.build.toplevel \
	.\#devShells.x86_64-linux.default

ATTRS_aarch64-linux := \
	.\#nixosConfigurations.serengeti.config.system.build.toplevel \
	.\#nixOnDroidConfigurations.default.config.environment.path \
	.\#devShells.aarch64-linux.default

ATTRS_aarch64-darwin := \
	.\#darwinConfigurations.katavi.system \
	.\#darwinConfigurations.mikumi.system \
	.\#darwinConfigurations.work.system \
	.\#devShells.aarch64-darwin.default

# $(1) is the --eval-system value, left empty to evaluate as the host system.
define nix-build
	$(NIX) build --keep-going --no-link --show-trace --print-out-paths \
		$(if $(1),--eval-system $(1)) $(2)
endef

x86_64-linux aarch64-linux aarch64-darwin:
	$(call nix-build,$@,$(ATTRS_$@))

build-all:
	$(call nix-build,,$(ATTRS_x86_64-linux) $(ATTRS_aarch64-linux) $(ATTRS_aarch64-darwin))
