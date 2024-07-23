#!/usr/bin/env bash
set -eEuo pipefail
test -z "${DEBUG:-}" || set -x
test -n "${PRJ_ROOT:-}" || eval "$(cd "${BASH_SOURCE[0]%/*}" && direnv export bash)"
cd "${BASH_SOURCE[0]%/*}"

key="disk-encryption-passphrase"
talos-pass exists "${key}" || pass generate "$(talos-pass path "${key}")" 32 >&2
passphrase="$(talos-pass read "${key}")"
export passphrase
gojq --yaml-input --yaml-output 'walk(if type == "object" and .static? then .static.passphrase |= env.passphrase end)' <.disk-encryption.yaml
