#!/usr/bin/env bash
set -eEuo pipefail
test -z "${DEBUG:-}" || set -x

log() {
  # shellcheck disable=SC2059
  printf "[${1}] ${2}\n" "${@:3}" >&2
}

handle_drive() {
  local json="$1" ret="" empties=() formatted=() unknowns=()
  local cur_uuid uuid candidates candidate name
  name="$(jq -r '.key' <<<"$json")"
  uuid="$(jq -r '.value.cfg.luks.uuid' <<<"$json")"
  uuid="${uuid,,}"
  export name uuid

  while read -r entry; do
    cur_uuid="$(cryptsetup luksUUID "${entry}" || :)"
    cur_uuid="${cur_uuid,,}"
    if test -z "${cur_uuid}"; then
      empties+=("${entry}")
    elif test "${cur_uuid}" == "${uuid}"; then
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
    ret=0
  fi
  test -z "${ret}" || return "${ret}"

  if test "${#empties[@]}" -gt 0; then
    candidate="${empties[0]}"
    log "${name}" "WARNING: you need to format the drive manually: ${candidate}"
    log "${name}" "  you can do that manually with:"
    log "${name}" "    k8s-nix-disks ${K8S_NODE_NAME:-"<NODE_NAME>"} disks-run ${name} disko --mode format --dry-run"
    log "${name}" "    k8s-nix-disks ${K8S_NODE_NAME:-"<NODE_NAME>"} disks-run ${name} disko --mode format "
    return 1
  elif test "${#formatted[@]}" -gt 0; then
    candidate="${formatted[0]}"
    log "${name}" "INFO: will mount: ${candidate}"
  else
    log "${name}" "ERROR: did not find any candidate"
    return 0
  fi
  disks-run "${name}" disko "${candidate}" --mode mount
}

ret=0
while read -r json; do
  handle_drive "$json" || ret="$?"
done < <(disks-jq -c 'to_entries[]')
exit "${ret}"
