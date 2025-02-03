{
  cell,
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
  packages = let
    helm = pkgs.wrapHelm pkgs.kubernetes-helm {
      plugins = with pkgs.kubernetes-helmPlugins; [
        helm-diff
        helm-git
      ];
    };

    holos = cell.packages.holos.override {kubernetes-helm = helm;};
  in
    with pkgs; [
      kubectl
      kustomize
      helmfile
      cilium-cli
      hubble
      helm
      holos
    ];
}
