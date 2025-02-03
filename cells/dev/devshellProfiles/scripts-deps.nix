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
    curl
    diffutils
    envsubst
    findutils
    gawk
    gnused
    gojq
    jq
    netcat
    pass
    rsync
    yq-go
    zstd
  ];
}
