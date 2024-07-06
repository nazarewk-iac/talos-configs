#!/usr/bin/env bash
set -xeEuo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
export workdir="${script_dir%/*}"
src_dir="$HOME/src"

nix_args=(
  --show-trace
  --print-build-logs
  --verbose
)
cp -rTL "${script_dir}/..data" "${src_dir}"
ln -sfT /hostfs/dev/disk /dev/disk

# shellcheck disable=SC2016
if ! nix develop "${nix_args[@]}" "${src_dir}" --command bash -xc '
  ln -sfT "${DEVSHELL_DIR}" ${workdir}/devshell
  set +x
  while true; do
    disks-setup
    sleep "${INTERVAL:-"60"}"
  done
'; then
  ret="$?"
  echo "ERROR ${ret}, waiting 10 minutes and exiting..."
  exit "${ret}"
fi
exec sleep infinity
