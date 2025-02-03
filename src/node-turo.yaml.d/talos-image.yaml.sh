#!/usr/bin/env bash
set -eEuo pipefail
trap 'info "Error when executing $BASH_COMMAND at line $LINENO!" >&2' ERR
info() { test "${LOG_LEVEL:-20}" -ge 20 || echo "[$(date -Iseconds)]" "$@" >&2; }
debug() { test "${LOG_LEVEL:-20}" -ge 10 || echo "[$(date -Iseconds)]" "$@" >&2; }
debug "STARTING $*"
trap 'debug "FINISHED $*"' EXIT
test -n "${PRJ_ROOT:-}" || eval "$(cd "${BASH_SOURCE[0]%/*}" && direnv export bash)"
test -z "${DEBUG:-}" || set -x
cd "${BASH_SOURCE[0]%/*}"

cat <<EOF
# Talos machine configuration patch
machine:
  install:
    image: '$(talos-image-url turo upgrade)'
EOF
