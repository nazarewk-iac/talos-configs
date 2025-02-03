#!/usr/bin/env bash
set -eEuo pipefail
trap 'info "Error when executing $BASH_COMMAND at line $LINENO!" >&2' ERR
info() { test "${LOG_LEVEL:-20}" -ge 20 || echo "[$(date -Iseconds)]" "$@" >&2; }
debug() { test "${LOG_LEVEL:-20}" -ge 10 || echo "[$(date -Iseconds)]" "$@" >&2; }
debug "STARTING $*"
trap 'debug "FINISHED $*"' EXIT
test -n "${PRJ_ROOT:-}" || eval "$(cd "${BASH_SOURCE[0]%/*}" && direnv export bash)"
test -z "${DEBUG:-}" || set -x

key="secrets.yaml"
while ! talos-pass exists "${key}"; do
  read -r -p "Talos secrets not found, write a new set (y/n)?" choice >&2
  case "$choice" in
  y | Y)
    talosctl gen secrets --force -o /dev/stdout | talos-pass write "${key}" >&2
    ;;
  n | N)
    echo "no"
    exit 1
    ;;
  *)
    echo "invalid"
    ;;
  esac
done
talos-pass read "${key}"
