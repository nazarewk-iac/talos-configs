{
  device, # result of `disks-run rant-local search`
  name, # eg: rant-local
  luksUUID, # generate with: `uuidgen`
  keyFile ? "/nix-disks/passphrases/${name}",
  cryptedName ? "${name}-crypted",
  poolName ? name,
  ...
}: {
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
  };
}
