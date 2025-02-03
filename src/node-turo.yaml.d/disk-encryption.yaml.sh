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

key="disk-encryption-passphrase"
talos-pass exists "${key}" || pass generate "$(talos-pass path "${key}")" 32 >&2
passphrase="$(talos-pass read "${key}")"
export passphrase
gojq --yaml-input --yaml-output 'walk(if type == "object" and .static? then .static.passphrase |= env.passphrase end)' <.disk-encryption.yaml
