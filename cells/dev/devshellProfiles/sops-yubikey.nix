{
  pkgs,
  lib,
  cell,
  ...
}: {
  env = [];
  packages = with pkgs; [
    #cell.packages.sops
    age
    age-plugin-yubikey
  ];
}
