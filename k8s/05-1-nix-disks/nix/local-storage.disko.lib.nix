{
  device, # result of `disks-run rant-local search`
  name, # eg: pic-local
  luksUUID, # generate with: `uuidgen`
  keyFile ? "/nix-disks/passphrases/${luksUUID}",
  cryptedName ? "${name}-crypted",
  poolName ? name,
  ...
}: let
  mkFs = cfg: let
    opt = cfg.mountpoint or "none";
    mountpoint = cfg.mountpoint or null;
  in
    {
      type = "zfs_fs";
      options.mountpoint = opt;
    }
    // cfg
    // {inherit mountpoint;};
in {
  disko.devices.disk."${cryptedName}" = {
    type = "disk";
    inherit device;
    content = {
      type = "luks";
      name = cryptedName;
      settings.keyFile = keyFile;
      extraFormatArgs = [
        "--uuid=${luksUUID}"
      ];
      content = {
        type = "zfs";
        pool = poolName;
      };
    };
  };
  disko.devices.zpool."${poolName}" = {
    type = "zpool";
    name = poolName;
    rootFsOptions = {
      acltype = "posixacl";
      relatime = "on";
      xattr = "sa";
      dnodesize = "auto";
      normalization = "formD";
      mountpoint = "none";
      canmount = "off";
      devices = "off";
      compression = "lz4";
      "com.sun:auto-snapshot" = "false";
    };
    options = {
      ashift = "12";
      "feature@large_dnode" = "enabled"; # required by dnodesize!=legacy
    };
    datasets = builtins.mapAttrs (name: mkFs) {
      "internal" = {
        mountpoint = "/var/lib/internal";
        options."com.sun:auto-snapshot" = "true";
      };
      "internal/openebs/zfs-localpv" = {
        mountpoint = "/var/lib/internal/openebs/zfs-localpv";
      };
      "internal/openebs/zfs-localpv/provisioned" = {
        options."com.sun:auto-snapshot" = "false";
      };
      "internal/rook/pic-rook" = {
        mountpoint = "/var/lib/internal/rook/pic-rook";
      };
    };
  };
}
