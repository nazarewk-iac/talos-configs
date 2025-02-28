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

mkpassphrase() {
  local key="luks/$1"
  talos-pass exists "${key}" || pass generate "$(talos-pass path "${key}")" 32 >&2
  talos-pass read "${key}"
}

secrets="{}"
while read -r uuid; do
  uuid="${uuid,,}"
  passphrase="$(mkpassphrase "${uuid}")"
  export passphrase uuid
  secrets="$(gojq '.[env.uuid] = env.passphrase' <<<"${secrets}")"
done < <(nix run "${PRJ_ROOT}/k8s/05-1-nix-disks/nix#jq" -- -r 'to_entries[].value.cfg.luks.uuid')

gojq --yaml-output '[{
  apiVersion: "v1",
  kind: "Secret",
  metadata: {
    name: "nix-disks-passphrases",
    namespace: "nix-system",
  },
  type: "Opaque",
  data: with_entries(.value |= @base64),
}]
| {
  apiVersion: "v1",
  kind: "List",
  items: .,
}
' <<<"${secrets}"
