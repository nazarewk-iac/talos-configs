{
  pkgs,
  lib,
  ...
}: {
  env = [
    {
      name = "KUBECONFIG";
      eval = "$PRJ_CONFIG_HOME/kube/config";
    }
  ];
}
