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
  packages = with pkgs; [
    kubectl
    kustomize
    helmfile
    (pkgs.wrapHelm pkgs.kubernetes-helm {
      plugins = with pkgs.kubernetes-helmPlugins; [
        helm-diff
        helm-git
      ];
    })
  ];
}
