#!/usr/bin/env bash
set -eEuo pipefail
test -z "${DEBUG:-}" || set -x
cd "${BASH_SOURCE[0]%/*}"

zap_disk() {
  # see https://rook.io/docs/rook/latest-release/Getting-Started/ceph-teardown/#zapping-devices
  local host="$1" type="$2" disk="$3"
  # ${XXX@Q} escapes string for input in another
  local cmds=(
    "sgdisk --zap-all ${disk@Q}"
  )

  local dd_clear="dd if=/dev/urandom of=${disk@Q} bs=1M count=100 oflag=direct,dsync"

  case "${type}" in
  hdd)
    cmds+=("${dd_clear}")
    ;;
  ssd | nvme)
    cmds+=("blkdiscard ${disk@Q} || ${dd_clear}")
    ;;
  *)
    echo "Invalid disk type: ${type}" >&2
    exit 1
    ;;

  esac
  k8s-nix-disks "${host}" bash -xeEuo pipefail -c "$(printf "%s\n" "${cmds[@]}")" 2>&1 | sed "s#^#[${host}:zap_disk(${disk})] #g"
}

clean_node() {
  # see https://rook.io/docs/rook/latest-release/Getting-Started/ceph-teardown/#zapping-devices
  local host="$1" disks=("${@:2}")
  local cmds=(
    "find /host/var/lib/internal/rook/pic-rook -mindepth 1 -delete"
  )
  k8s-nix-disks "${host}" bash -xeEuo pipefail -c "$(printf "%s\n" "${cmds[@]}")" 2>&1 | sed "s/^/[${host}:clean_node()] /g"
  for disk in "${disks[@]}"; do
    zap_disk "${host}" "${disk%%:*}" "${disk#*:}"
  done
}
expected_date="$(date -u '+%Y-%m-%d %H:%M')"
: "${CONFIRM_DATE:=""}"
test "${CONFIRM_DATE}" == "${expected_date}" || {
  echo "\$CONFIRM_DATE='${CONFIRM_DATE}' doesn't match '${expected_date}', rerun with:"
  echo "CONFIRM_DATE='${expected_date}' $0 $*"
  exit 1
}

clean_node pwet \
  hdd:/dev/disk/by-id/wwn-0x5000c500e0cd37a6 \
  ssd:/dev/disk/by-id/wwn-0x500a0751e8764b59

clean_node turo \
  hdd:/dev/disk/by-id/wwn-0x5000c500ecc2f1e3 \
  ssd:/dev/disk/by-id/wwn-0x500a0751e6d95db1

clean_node yost \
  hdd:/dev/disk/by-id/wwn-0x5000c500c0297738 \
  ssd:/dev/disk/by-id/wwn-0x500a0751e8767e4c
