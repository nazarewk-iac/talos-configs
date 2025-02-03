{
  lib,
  buildGo123Module,
  fetchFromGitHub,
  nix-update-script,
  kubernetes-helm,
  kubectl,
  makeWrapper,
}:
buildGo123Module rec {
  pname = "holos";
  version = "0.101.5";

  nativeBuildInputs = [
    kubernetes-helm
    kubectl
    makeWrapper
  ];

  src = fetchFromGitHub {
    owner = "holos-run";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-01XG4PyAxYvzgWutTCvLZy8MpFuxdznujgRgJ+aSXGI=";
  };

  vendorHash = "sha256-ChWvc7wu42BnG4DeoSV6XL1DhL/nlr0CKXD/cfNW8JA=";

  subPackages = ["cmd/holos"];

  ldflags = ["-s" "-w"];

  passthru.updateScript = nix-update-script {};

  postInstall = ''
    wrapProgram "$out/bin/holos" \
      --suffix PATH : "${lib.makeBinPath [kubernetes-helm kubectl]}"
  '';

  meta = with lib; {
    homepage = "https://github.com/holos-run/holos";
    description = "Holos - The Holistic platform manager";
    mainProgram = "holos";
    maintainers = with maintainers; [nazarewk];
    license = licenses.asl20;
  };
}
