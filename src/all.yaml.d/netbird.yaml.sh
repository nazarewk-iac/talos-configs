#!/usr/bin/env bash
set -eEuo pipefail
test -z "${DEBUG:-}" || set -x
test -n "${PRJ_ROOT:-}" || eval "$(cd "${BASH_SOURCE[0]%/*}" && direnv export bash)"
cd "${BASH_SOURCE[0]%/*}"

setup_key="$(talos-pass read "netbird-setup-key")"
export setup_key
gojq --yaml-input --yaml-output 'walk(if type == "object" and .name? and .name == "NB_SETUP_KEY" then .value |= env.setup_key end)' <.netbird.yaml
