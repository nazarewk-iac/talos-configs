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
    {
      name = "KUBECONFIG";
      eval = "$PRJ_CONFIG_HOME/kube/config";
    }
  ];
}
