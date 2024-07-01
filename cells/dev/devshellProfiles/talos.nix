{
  pkgs,
  lib,
  ...
}: {
  env = [
    {
      name = "TALOSCONFIG";
      eval = "$PRJ_CONFIG_HOME/talos/config";
    }
  ];
}
