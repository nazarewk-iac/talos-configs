# dependencies from ./bin scripts
{
  pkgs,
  lib,
  ...
}: {
  env = lib.mkOrder 400 [
    {
      name = "PATH";
      eval = "$PRJ_ROOT/bin:$PATH";
    }
  ];
  packages = with pkgs; [
    jq
    gnused
    findutils
    pass
    diffutils
    curl
    netcat
    yq-go
  ];
}
