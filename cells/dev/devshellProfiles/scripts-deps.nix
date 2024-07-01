# dependencies from ./bin scripts
{
  pkgs,
  lib,
  ...
}: {
  packages = with pkgs; [
    jq
    gnused
    findutils
    pass
  ];
}
