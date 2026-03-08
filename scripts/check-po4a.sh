#!/usr/bin/env bash
set -euo pipefail

po4a po4a.cfg
check-git-changes "po4a updated translation files." -- po/ '*.ja.org'
