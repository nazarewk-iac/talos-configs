#!/usr/bin/env bash
set -eEuo pipefail
test -z "${DEBUG:-}" || set -x

log() {
  # shellcheck disable=SC2059
  printf "[${1}] ${2}\n" "${@:3}" >&2
}

handle_drive() {
  local name="$1" ret="" empties=() formatted=() unknowns=()
  local uuid config_uuid candidates candidate
  export name
  config_uuid="$(disks-jq -r '.[env.name].cfg.luks.uuid')"

  while read -r entry; do
    uuid="$(cryptsetup luksUUID "${entry}" || :)"
    if test -z "${uuid}"; then
      empties+=("${entry}")
    elif test "${uuid}" == "${config_uuid}"; then
      formatted+=("${entry}")
    else
      unknowns+=("${entry}")
    fi
  done < <(disks-run "$name" search)
  candidates=(
    "${formatted[@]}"
    "${empties[@]}"
    "${unknowns[@]}"
  )
  test "${#formatted[@]}" -eq 0 || log "${name}" "OK %s" "${formatted[@]}"
  test "${#empties[@]}" -eq 0 || log "${name}" "EMPTY %s" "${empties[@]}"

  if test "${#unknowns[@]}" -gt 0; then
    log "${name}" "WARNING: found UNKNOWN device %s" "${unknowns[@]}"
    ret=0
  fi

  if test "${#candidates[@]}" -gt 1; then
    log "${name}" "ERROR: found more than 1 device: ${candidates[*]}"
    ret=1
  elif test "${#candidates[@]}" -eq 0; then
    log "${name}" "INFO: did not find any devices"
  fi
  test -z "${ret}" || return "${ret}"

  if test "${#empties[@]}" -gt 0; then
    candidate="${empties[0]}"
    log "${name}" "WARNING: you need to format the drive manually: ${candidate}"
    log "${name}" "  you can do that manually with:"
    log "${name}" "    talos-nix-disks ${K8S_NODE_NAME:-"<NODE_NAME>"} disks-run ${name} disko --mode format --dry-run"
    log "${name}" "    talos-nix-disks ${K8S_NODE_NAME:-"<NODE_NAME>"} disks-run ${name} disko --mode format "
    return 1
  else
    candidate="${formatted[0]}"
    log "${name}" "INFO: will mount: ${candidate}"
  fi
  disks-run "${name}" disko "${candidate}" --mode mount
}

ret=0
while read -r name; do
  handle_drive "$name" || ret="$?"
done < <(disks-jq -r 'to_entries[].value.name')
exit "${ret}"
