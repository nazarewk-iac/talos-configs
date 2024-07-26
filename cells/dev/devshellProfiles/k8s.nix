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
    {
      name = "KUBECACHEDIR";
      eval = "$PRJ_CACHE_HOME/kube";
    }
  ];
  packages = with pkgs; [
    kubectl
    kustomize
    helmfile
    cilium-cli
    hubble
    (pkgs.wrapHelm pkgs.kubernetes-helm {
      plugins = with pkgs.kubernetes-helmPlugins; [
        helm-diff
        helm-git
      ];
    })
  ];
}
