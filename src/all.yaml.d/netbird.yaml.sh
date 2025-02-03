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

setup_key="$(talos-pass read "netbird-setup-key")"
export setup_key
gojq --yaml-output --null-input '{ cluster: { inlineManifests: [{
  name: "netbird-namespace",
  contents: ({
    "apiVersion": "v1",
    "kind": "Namespace",
    "metadata": {
      "name": "netbird-system",
      "labels": {
        "pod-security.kubernetes.io/audit": "privileged",
        "pod-security.kubernetes.io/enforce": "privileged",
        "pod-security.kubernetes.io/warn": "privileged"
      }
    }
  } | tojson)
}, {
  name: "netbird-secrets",
  contents: ({
    "apiVersion": "v1",
    "kind": "Secret",
    "metadata": {
      "name": "netbird-env",
      "namespace": "netbird-system"
    },
    "type": "Opaque",
    "stringData": {
      "NB_SETUP_KEY": env.setup_key
    }
  } | tojson)
}]}}'
