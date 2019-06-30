.PHONY: brew-extra core init link local minimum

minimum: core link init

link:
	$(PWD)/bin/link.sh

init:
	$(PWD)/bin/init.sh

core:
	$(PWD)/bin/core.sh

local:
	$(PWD)/bin/local.sh

brew-extra:
	brew bundle --file=$PWD/homebrew/Brewfile-extra
