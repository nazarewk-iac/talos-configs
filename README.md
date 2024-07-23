# talos-configs

Repository containing my personal Talos Kubernetes setup.

# Usage overview

```shell
nix develop --command fish

# (re-)generate configurations
talos-gen

# generate an ISO
talos-installer-disk-write /dev/disk/by-id/usb-Samsung_Portable_SSD_T5_1234567D585A-0:0 pwet iso

# in BIOS enter Secure Boot "Setup Mode" (becomes visible when doing custom secure boot)
# plug in the USB
# select from Talos boot menu: `Enroll Secure Boot keys: auto`
# confirm presence of the new keys in BIOS (Secure Boot active and/or custom keys present)

# first node
talos-node-apply --insecure pwet

# boostrap only the first nose
talosctl-node pwet bootstrap

talosctl-node pwet kubeconfig --force
kubectl get node
kubectl get pod -A

# rest of nodes
talos-node-apply --insecure turo yost
kubectl get node
kubectl get pod -A
```

# Overview

It is running dual-stack (both LAN and WAN) on a mix of 10/2.5/1 GbE (mostly managed) switches.

## Primary nodes

Runs on 3x self-built Mini ITX NAS boxes, each consisting of:

- [SzBox N100 mobo](https://www.amazon.pl/dp/B0CQ4PX7WX):
  - seems to be searchable under `CWWK N100`
  - 4x 2.5GbE ethernet
  - 2x NVMe connectors
  - 6x SATA connectors
- [Jonsbo N2](https://www.jonsbo.com/en/products/N2Black.html) case:
  - 5x 3.5" removable SATA
  - 2x 2.5" SATA mounted inside
- 32GB RAM
- drives:
  - 250GB NVMe as Talos system drive
  - 1TB NVMe as the primary cache/local storage
  - 1TB SSD for Ceph storage
  - 4TB HDD for Ceph storage

## Raspberry Pi4 nodes

Not running yet, but keeping the section

Runs on 3x Raspberry Pi 4 4GB, each holding:

- [UEFI-boot](https://github.com/pftf/RPi4) SD card having ONLY boot configuration (see Boot sequence issues)
- (any) SD card holding [RPi4 UEFI-boot](https://github.com/pftf/RPi4) and nothing else
- 1x small ~256 GB SSDs holding encrypted Talos system partitions: `STATE` and `EPHEMERAL`

### RPi4 scope

## Scope

- [x] integrate with Nix-based development environment
- [x] securely store sensitive data/configuration using `pass`:
  - [x] read/write/sync using `talos-pass`
- [x] dual-stack (IPv4 + IPv6)
- [ ] use Cilium CNI
- [x] figure out update/upgrade/reconfiguration procedures:
  - [x] reconfigure nodes using `talos-node-apply`
  - [x] upgrade (Talos) nodes using `talos-node-upgrade`
  - [x] use Image Factory to customize Talos images using `talos-image`
  - [x] add ZFS system extension
  - [x] pin Kubernetes version to upgrade separately from Talos
- [x] set up ZFS on LUKS on the 1TB drive for local storage
  - [x] make those accessible with [OpenEBS local storage](https://openebs.io/docs/concepts/data-engines/localstorage) engine
- [x] access from anywhere with Netbird
- [x] run arbitrary Nix tooling within the cluster
  - see `k8s-nix-disks` or `nix-system/nix-disks` daemonset configuration
  - [ ] put container gcroots (maybe profiles?) into subdirectories on host
  - [ ] write some controller/operator to inject Nix configs into Pod automatically?
- [ ] resolve `*.pic.kdn.im` DNS names
- [ ] check whether 4x2.5GbE ethernets could be bonded into 10GbE
- [x] set up Rook/Ceph
  - [x] set up CephCluster on RPi4s
  - [ ] set up first disk pools
- [ ] separate Ceph configurations for:
  - [ ] SSDs: replicated frequent/lower latency access
  - [ ] HDDs: infrequent/large files access
  - [ ] HDDs: long term backups
- [ ] run Nextcloud?
- [ ] offline-synced backup solution?

### RPi4 scope

- [x] set up Talos on multi-disk Raspberry Pi 4:
  - [x] [RPi4 UEFI-boot](https://github.com/pftf/RPi4) SD card having ONLY boot configuration (see Boot sequence
        issues)
    - [x] reconfigure rpi4 `BOOT_SEQUENCE`
    - [ ] investigate whether `config.txt` should be copied to UEFI from Talos partition?
  - [x] prepare & boot Talos installer USB disk
  - [x] bootstraping cluster

# First time setup

Based on following materials:

- https://www.talos.dev/v1.7/talos-guides/install/single-board-computers/rpi_generic/
- https://www.sidero.dev/v0.6/guides/rpi4-as-servers/

## Preparing CWWK N100

- [ ] boot the Talos Installer SecureBoot ISO & select `Enroll Secure Boot keys: auto` from boot menu
- [ ] reboot into Talos Installer ISO, note down the IP or get it from router `fd31:e17c:f07f:1:aab8:e0ff:fe04:130d`
- [ ] set up `hostname.yaml`
- [ ] set up `install-disk.yaml`:
  - `talosctl -n fd31:e17c:f07f:1:aab8:e0ff:fe04:130d disks --insecure`
- [ ] set up `networking.yaml`:
  - generate DUID with `uuidget | tr -d '-'`, store it here and in `config.json`
  - `talosctl -n fd31:e17c:f07f:1:aab8:e0ff:fe04:130d get addresses --insecure`
- [ ] fill in all network interfaces:
  - `talosctl -n fd31:e17c:f07f:1:aab8:e0ff:fe04:130d get link --insecure`
- run `talos-gen`
- [ ] apply node config:
  - `talos-node-apply --insecure turo`

## Preparing Raspberry Pi 4

On Nix+Sway RPI Imager (eg: configure EEPROM) can be run
with [`_sway-root-gui --enable`](https://github.com/nazarewk-iac/nix-configs/blob/899813900c65b3d7f82c154d943790559dcb870d/modules/desktop/sway/default.nix#L320-L328)
and `sudo nix run 'nixpkgs#rpi-imager'`.

1. load SD card with #rpi4-uefi (can be done through #rpi-imager)
2. load USB drive/disk with `metal-rpi_generic-arm64.raw.xz` #talos release using #rpi-imager or `dd`
3. load and boot another SD card with `SD > USB boot EEPROM` using #rpi-imager
4. boot it to configure for SD card boot
5. enter UEFI setup:
6. (optionally?) disconnect all of USB drives
7. boot #rpi4-uefi SD card (it should stay as the primary boot option forever)

- TODO: possibly copy-over the `config.txt` from Talos partition?

8. wait for rasbperry logo on black background

- press `ESC` immediately (before the loader expires)

9. you are now at UEFI setup (looks like a BIOS setup)
10. (optionally?) connect all USB drives
11. make sure the boot USB drive is connected
12. set up #rpi4-uefi (go back with `F10` > `Y` > `ESC` to save settings whenever possible)

- `Device Manager`
  - `Rasbperry Pi Configuration`
    - `Display Configuration`
      - enable `Virtual 720p` and nothing else
        - this is the most legible option on Gembird UHG-4K2-01 HDMI
          grabber https://gembird.com/item.aspx?id=12083
    - `Advanced Configuration`
      - disable `Limit RAM to 3 GB`
- `Boot Maintenance Manager`
  - `Boot Discovery Policy`
    - set to `Minimal`
  - (optionally) change `Auto Boot Time-out` from `5` to `1` for faster boot
  - `Boot Options`
    - `Change Boot Order`
      - make sure the correct disk is first (it's the same as #talos
        config `machine.install.diskSelector.wwid` in
        case of `SK Hynix` drives over NVMe to USB adapters)
      - optionally delete all the other boot options
- `Reset`

6. Reboot the RPi4 into Talos

- wait for everything to boot (no pool.ntp.org errors after ~2-3 minutes)
- figure out:
  - ip address
    - try `nc -w 2 -z <ip> 50000`
  - mac address
- set up DNS name on `drek` (router)
- add entry to `config.json`

7. it should be possible to run `talos-node-apply` on the controlplane node

### Rasbperry Pi 4 boot sequence issues

Raspberry Pi 4 boots the first USB disk discovered by the board and does not retry any other disk.
Everything worked fine for me until I plugged in the second disk

I have worked around the issue by:

1. loading up a dedicated SD card with https://github.com/pftf/RPi4
2. making sure SD card boots first by
   modifying [`BOOT_ORDER`](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#BOOT_ORDER)

RPi4 UEFI has those characteristics:

- attempts to boot EVERY disk at least once before failing
- for some reason it very often tries 4 netboots (HTTP/iPXE + IPv4/IPv6) for a few minutes delay before finally getting
  to the local USB boot

# Day two operations

Updating/upgrading/debugging.

- `talosctl-node rant dmesg`
- `talosctl-node rant health`
- `talosctl etcd members`

## Disk management

### non-Talos disk management

```shell
kubectl apply -k k8s/nix-system
k8s-nix-disks rant
```

### Talos disk identification

In `talos disks` (actual inputs for cluster configs) USB adapters identify as the same device without meaningful difference between those.

After (probably) `udev` service is up you can list all disks and symlinks by `talosctl list /dev/disk/by-id --long`.

#### USB3.0 to powered SATA adapter

Best identified with `wwid`: `*DD56419883014*`

```
NODE        DEV            MODEL         SERIAL       TYPE   UUID   WWID                                              MODALIAS      NAME    SIZE     BUS_PATH                                                                                       SUBSYSTEM          READ_ONLY   SYSTEM_DISK
rant.lan.   /dev/sda       USB3.0        -            HDD    -      t10.ANKEJE  USB3.0          DD56419883014\0\0\0   scsi:t-0x00   -       1.0 TB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-1/3-1:1.0/host0/target0:0:0/0:0:0:0/           /sys/class/block
hurl.lan.   /dev/sdb       USB3.0        -            HDD    -      t10.ANKEJE  USB3.0          DD56419883014\0\0\0   scsi:t-0x00   -       1.0 TB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-1/3-1.1/3-1.1:1.0/host1/target1:0:0/1:0:0:0/   /sys/class/block
jhal.lan.   /dev/sdb       USB3.0        -            HDD    -      t10.ANKEJE  USB3.0          DD56419883014\0\0\0   scsi:t-0x00   -       1.0 TB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-1/3-1.3/3-1.3:1.0/host1/target1:0:0/1:0:0:0/   /sys/class/block
```

#### USB3.0 to M.2 SSD adapter

Best identified with `wwid`: `*DD564198838A3*`:

```
NODE        DEV            MODEL         SERIAL       TYPE   UUID   WWID                                              MODALIAS      NAME    SIZE     BUS_PATH                                                                                       SUBSYSTEM          READ_ONLY   SYSTEM_DISK
rant.lan.   /dev/sdb       Super Speed   -            HDD    -      t10.USB3.0  Super Speed     DD564198838A3\0\0\0   scsi:t-0x00   -       256 GB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-2/3-2:1.0/host1/target1:0:0/1:0:0:0/           /sys/class/block               *
hurl.lan.   /dev/sda       Super Speed   -            HDD    -      t10.USB3.0  Super Speed     DD564198838A3\0\0\0   scsi:t-0x00   -       256 GB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-2/3-2:1.0/host0/target0:0:0/0:0:0:0/           /sys/class/block               *
jhal.lan.   /dev/sda       Super Speed   -            HDD    -      t10.USB3.0  Super Speed     DD564198838A3\0\0\0   scsi:t-0x00   -       256 GB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-2/3-2:1.0/host0/target0:0:0/0:0:0:0/           /sys/class/block               *
```

#### All connected disks

<details>
  <summary><code>talosctl disks</code></summary>

```
[TALOSCTL] /home/kdn/dev/github.com/nazarewk-iac/talos-configs/talos-1.7.5/talosctl-linux-amd64 --cluster=pic disks
NODE        DEV            MODEL             SERIAL       TYPE   UUID   WWID                   MODALIAS      NAME    SIZE     BUS_PATH                                                                               SUBSYSTEM          READ_ONLY   SYSTEM_DISK
rant.lan.   /dev/mmcblk1   -                 0x28fbade5   SD     -      -                      -             SA32G   31 GB    /system/container/ACPI0004:01/BRCME88C:00/mmc_host/mmc1/mmc1:1234/                     /sys/class/block
rant.lan.   /dev/sda       500SSD1           -            HDD    -      -                      scsi:t-0x00   -       1.0 TB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-1/3-1:1.0/host0/target0:0:0/0:0:0:0/   /sys/class/block
rant.lan.   /dev/sdb       001-2MA101        -            HDD    -      -                      scsi:t-0x00   -       4.0 TB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-1/3-1:1.0/host0/target0:0:0/0:0:0:1/   /sys/class/block
rant.lan.   /dev/sdc       Portable SSD T5   -            SSD    -      naa.5000000000000001   scsi:t-0x00   -       250 GB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-2/3-2:1.0/host1/target1:0:0/1:0:0:0/   /sys/class/block               *
rant.lan.   /dev/sdd       500SSD1           -            HDD    -      -                      scsi:t-0x00   -       2.0 TB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-1/3-1:1.0/host0/target0:0:0/0:0:0:2/   /sys/class/block
jhal.lan.   /dev/mmcblk1   -                 0x28fbace4   SD     -      -                      -             SA32G   31 GB    /system/container/ACPI0004:01/BRCME88C:00/mmc_host/mmc1/mmc1:1234/                     /sys/class/block
jhal.lan.   /dev/sda       500SSD1           -            HDD    -      -                      scsi:t-0x00   -       1.0 TB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-1/3-1:1.0/host0/target0:0:0/0:0:0:0/   /sys/class/block
jhal.lan.   /dev/sdb       001-2MA101        -            HDD    -      -                      scsi:t-0x00   -       4.0 TB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-1/3-1:1.0/host0/target0:0:0/0:0:0:1/   /sys/class/block
jhal.lan.   /dev/sdc       Super Speed       -            HDD    -      -                      scsi:t-0x00   -       256 GB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-2/3-2:1.0/host1/target1:0:0/1:0:0:0/   /sys/class/block               *
jhal.lan.   /dev/sdd       500SSD1           -            HDD    -      -                      scsi:t-0x00   -       2.0 TB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-1/3-1:1.0/host0/target0:0:0/0:0:0:2/   /sys/class/block
hurl.lan.   /dev/mmcblk1   -                 0x28fbad8b   SD     -      -                      -             SA32G   31 GB    /system/container/ACPI0004:01/BRCME88C:00/mmc_host/mmc1/mmc1:1234/                     /sys/class/block
hurl.lan.   /dev/sda       500SSD1           -            HDD    -      -                      scsi:t-0x00   -       1.0 TB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-1/3-1:1.0/host0/target0:0:0/0:0:0:0/   /sys/class/block
hurl.lan.   /dev/sdb       Super Speed       -            HDD    -      -                      scsi:t-0x00   -       256 GB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-2/3-2:1.0/host1/target1:0:0/1:0:0:0/   /sys/class/block               *
hurl.lan.   /dev/sdc       00AAKS-00A7B0     -            HDD    -      -                      scsi:t-0x00   -       500 GB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-1/3-1:1.0/host0/target0:0:0/0:0:0:1/   /sys/class/block
hurl.lan.   /dev/sdd       001-1ER164        -            HDD    -      -                      scsi:t-0x00   -       2.0 TB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-1/3-1:1.0/host0/target0:0:0/0:0:0:2/   /sys/class/block
hurl.lan.   /dev/sde       P210 2048GB       -            HDD    -      -                      scsi:t-0x00   -       2.0 TB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-1/3-1:1.0/host0/target0:0:0/0:0:0:3/   /sys/class/block
```

</details>

## updating machine config

```shell
talos-node-apply --dry-run hurl
talos-node-apply hurl
```

## checking machine config drift

```shell
talos-node-apply --dry-run '*'
talos-node-apply --check
```

## upgrading install image (extensions etc.)

this command will update to latest configured

```shell
talos-node-upgrade hurl
```

might need to run `talos-node-apply hurl` after reboot to load the ZFS kernel module before the boot finishes

debug system messages with `talosctl-node hurl dmesg --follow`

# Discovered issues

- most cheap SATA -> USB disk bays require physically pressing a button to turn on after losing power, so far:

  - `ORICO-6648US3-C-V1`
  - `ORICO-6558US3-C`
  - `StarTech SDOCK4U313`
  - `Fantec QB-35US3R`

- `ORICO-6648US3-C-V1` seems to garble drive's metadata:
  - all 3 [Crucial BX500 1TB](https://www.crucial.com/ssd/bx500/ct1000bx500ssd1) plugged into different RPi4
    appear EXACTLY the same in `lsblk -OJ`

## improvement ideas

- replace rpi4 with NAS kit like https://wiki.friendlyelec.com/wiki/index.php/CM3588
- look for HBA expansion cards?
