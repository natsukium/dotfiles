#!/usr/bin/env bash
set -euo pipefail

make -B tangle -j
check-git-changes "Org files were out of sync and have been auto-tangled."
