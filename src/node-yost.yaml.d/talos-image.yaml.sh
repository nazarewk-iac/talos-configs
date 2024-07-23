#!/usr/bin/env bash
set -eEuo pipefail
test -z "${DEBUG:-}" || set -x
test -n "${PRJ_ROOT:-}" || eval "$(cd "${BASH_SOURCE[0]%/*}" && direnv export bash)"
cd "${BASH_SOURCE[0]%/*}"

cat <<EOF
# Talos machine configuration patch
machine:
  install:
    image: '$(talos-image yost upgrade)'
EOF
