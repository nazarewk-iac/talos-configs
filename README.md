# talos-configs

Repository containing my personal Talos Kubernetes configurations

# overview

#talos #rpi4 #install based on https://www.talos.dev/v1.6/talos-guides/install/single-board-computers/rpi_generic/

```shell
direnv allow

# first node
talos-apply --insecure rant
# boostrap only once
talosctl-node rant bootstrap

talosctl-node rant kubeconfig --force
kubectl get node
kubectl get pod -A

# rest of nodes
talos-apply --insecure hurl jhal
kubectl get node
kubectl get pod -A
```

# raspberry pi 4 preparation

first parts of sidero metal guide are helpful https://www.sidero.dev/v0.6/guides/rpi4-as-servers/ , thanks
to [Luke Carrier]() at Matrix chat

#rpi-imager can be run with `_sway-root-gui --enable; sudo nix run 'nixpkgs#rpi-imager'`

#talos releases https://github.com/siderolabs/talos/releases

#rpi4-uefi https://github.com/pftf/RPi4

1. load SD card with #rpi4-uefi (can be done through #rpi-imager)
2. load USB drive with `metal-rpi_generic-arm64.raw.xz` #talos release using #rpi-imager
3. load and boot another SD card with SD > USB boot EEPROM using #rpi-imager
    1. boot it to configure the built-in RPI4 firmware configured for SD card boot
4. enter UEFI setup:
    1. (optionally?) disconnect all of USB drives
    2. boot #rpi4-uefi SD card (it should stay as the primary boot option forever)
        - TODO: possibly copy-over the `config.txt` from Talos partition?
    3. wait for rasbperry logo on black background
        - press `ESC` immediately (before the loader expires)
    4. you are now at UEFI setup (looks like a BIOS setup)
    5. (optionally?) connect all USB drives
    6. make sure the boot USB drive is connected
5. set up #rpi4-uefi (go back with `F10` > `Y` > `ESC` to save settings whenever possible)
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
            - try `nc -z <ip> 50000`
        - mac address
    - set up DNS name on `drek` (router)
    - add entry to `config.json`
7. it should be possible to run `talos-apply` on the controlplane node

# debugging

- `talosctl-node rant dmesg`
- `talosctl-node rant health`
- `talosctl etcd members`

# disks identification

USB adapters identify as the same device without meaningful difference between those.

## USB3.0 to powered SATA adapter

Best identified with `wwid`: `*DD56419883014*`

```
NODE        DEV            MODEL         SERIAL       TYPE   UUID   WWID                                              MODALIAS      NAME    SIZE     BUS_PATH                                                                                       SUBSYSTEM          READ_ONLY   SYSTEM_DISK
rant.lan.   /dev/sda       USB3.0        -            HDD    -      t10.ANKEJE  USB3.0          DD56419883014\0\0\0   scsi:t-0x00   -       1.0 TB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-1/3-1:1.0/host0/target0:0:0/0:0:0:0/           /sys/class/block               
hurl.lan.   /dev/sdb       USB3.0        -            HDD    -      t10.ANKEJE  USB3.0          DD56419883014\0\0\0   scsi:t-0x00   -       1.0 TB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-1/3-1.1/3-1.1:1.0/host1/target1:0:0/1:0:0:0/   /sys/class/block               
jhal.lan.   /dev/sdb       USB3.0        -            HDD    -      t10.ANKEJE  USB3.0          DD56419883014\0\0\0   scsi:t-0x00   -       1.0 TB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-1/3-1.3/3-1.3:1.0/host1/target1:0:0/1:0:0:0/   /sys/class/block               
```

## USB3.0 to M.2 SSD adapter

Best identified with `wwid`: `*DD564198838A3*`:

```
NODE        DEV            MODEL         SERIAL       TYPE   UUID   WWID                                              MODALIAS      NAME    SIZE     BUS_PATH                                                                                       SUBSYSTEM          READ_ONLY   SYSTEM_DISK
rant.lan.   /dev/sdb       Super Speed   -            HDD    -      t10.USB3.0  Super Speed     DD564198838A3\0\0\0   scsi:t-0x00   -       256 GB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-2/3-2:1.0/host1/target1:0:0/1:0:0:0/           /sys/class/block               *
hurl.lan.   /dev/sda       Super Speed   -            HDD    -      t10.USB3.0  Super Speed     DD564198838A3\0\0\0   scsi:t-0x00   -       256 GB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-2/3-2:1.0/host0/target0:0:0/0:0:0:0/           /sys/class/block               *
jhal.lan.   /dev/sda       Super Speed   -            HDD    -      t10.USB3.0  Super Speed     DD564198838A3\0\0\0   scsi:t-0x00   -       256 GB   /system/container/ACPI0004:02/PNP0D10:00/usb3/3-2/3-2:1.0/host0/target0:0:0/0:0:0:0/           /sys/class/block               *
```