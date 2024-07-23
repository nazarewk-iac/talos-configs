#!/usr/bin/env bash
set -eEuo pipefail
test -z "${DEBUG:-}" || set -x
test -n "${PRJ_ROOT:-}" || eval "$(cd "${BASH_SOURCE[0]%/*}" && direnv export bash)"
cd "${BASH_SOURCE[0]%/*}"

service_cidr_ipv6="$(talos-pass read "service-cidr-ipv6")"
node_cidr_ipv6="$(talos-pass read "node-cidr-ipv6")"
export service_cidr_ipv6 node_cidr_ipv6
gojq --yaml-input --yaml-output '
.cluster.network.serviceSubnets += [env.service_cidr_ipv6]
| .machine.kubelet.nodeIP.validSubnets += [env.node_cidr_ipv6]
' <.dual-stack.yaml
