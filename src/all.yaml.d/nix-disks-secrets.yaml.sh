#!/usr/bin/env bash
set -eEuo pipefail
test -z "${DEBUG:-}" || set -x
test -n "${PRJ_ROOT:-}" || eval "$(cd "${BASH_SOURCE[0]%/*}" && direnv export bash)"
cd "${BASH_SOURCE[0]%/*}"

mkpassphrase() {
  local key="luks/$1"
  talos-pass exists "${key}" || pass generate "$(talos-pass path "${key}")" 32 >&2
  talos-pass read "${key}"
}

secrets="{}"
while read -r name; do
  passphrase="$(mkpassphrase "${name}")"
  export passphrase
  secrets="$(gojq '.[env.name] = env.passphrase' <<<"${secrets}")"
done < <(nix run "${PRJ_ROOT}/k8s/nix-system/nix-disks/nix#jq" -- -r 'to_entries[].value.name')

gojq --yaml-output '[{
  apiVersion: "v1",
  kind: "Namespace",
  metadata: {
    name: "nix-system",
  },
},{
  apiVersion: "v1",
  kind: "Secret",
  metadata: {
    name: "nix-disks-passphrases",
    namespace: "nix-system",
  },
  type: "Opaque",
  data: with_entries(.value |= @base64),
}]
| {cluster:{inlineManifests: map({
  name: ("\(.kind)-\(.metadata.namespace)-\(.metadata.name)" | ascii_downcase),
  contents: @json,
})}
}' <<<"${secrets}"
