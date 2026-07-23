#!/usr/bin/env bash
set -euo pipefail

output=build
langs="en ja"

while [ $# -gt 0 ]; do
  case $1 in
  -o | --output)
    output=$2
    shift 2
    ;;
  -l | --langs)
    langs=$2
    shift 2
    ;;
  *)
    echo "usage: build-html.sh [--output DIR] [--langs 'en ja']" >&2
    exit 1
    ;;
  esac
done

cd "$(dirname "$0")/.."

# Translations are anchored by the English slugs, so English is always built and
# always built first. Asking for a translation alone would otherwise fail.
translations=$(tr ' ' '\n' <<<"$langs" | grep -vx -e en -e '' | tr '\n' ' ' || true)
langs="en $translations"

# po4a regenerates the translated Org documents from po/ja.po, so only a build
# that includes a translation needs it. Skipping it is what lets an
# English-only build run outside the dev shell, the only place po4a is
# installed.
if [ -n "$translations" ]; then
  po4a po4a.cfg
fi

DOTFILES_HTML_LANGS="$langs" emacs --batch -l scripts/org-to-html.el

for lang in $langs; do
  if [ "$lang" = en ]; then
    exported=configuration.html
    published=$output/index.html
  else
    exported=configuration.$lang.html
    published=$output/$lang/index.html
  fi
  # mkdir then install, rather than install -D, because BSD install has no -D
  # and this runs on macOS as well as in the Linux sandbox.
  mkdir -p "$(dirname "$published")"
  install -m644 "$exported" "$published"
  rm -f "$exported"
done
