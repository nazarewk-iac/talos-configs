{
  description = "virtual environments";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.devshell.url = "github:numtide/devshell";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  outputs = inputs @ {
    self,
    flake-parts,
    devshell,
    nixpkgs,
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        devshell.flakeModule
      ];

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      perSystem = {
        pkgs,
        lib,
        ...
      }: let
        disks = import ./disks.nix {inherit pkgs;};
        disksFile = pkgs.writeText "disks.json" (builtins.toJSON disks);
        bin.jq = pkgs.writeShellApplication {
          name = "disks-jq";
          runtimeInputs = with pkgs; [jq];
          text = ''
            test -z "''${DEBUG:-}" || set -x
            : "''${DISKS_JSON:="${disksFile}"}"
            jq "$@" <"$DISKS_JSON"
          '';
        };
        bin.run = pkgs.writeShellApplication {
          name = "disks-run";
          runtimeInputs = with pkgs; [jq];
          text = ''
            test -z "''${DEBUG:-}" || set -x
            export name="$1"
            export script="$2"
            cmd="$(${lib.getExe bin.jq} -r ".[env.name].bin[env.script]")"
            shift 2
            exec "$cmd" "$@"
          '';
        };
        bin.render = pkgs.writeShellApplication {
          name = "disks-render";
          runtimeInputs = with pkgs; [bin.run];
          text = ''
            for name in "$@" ; do
              disks-run "$name" render
            done
          '';
        };
        bin.setup = pkgs.writeShellApplication {
          name = "disks-setup";
          runtimeInputs = with pkgs; [
            bin.run
            bin.jq
          ];
          text = builtins.readFile ./handle-drives.sh;
        };
      in {
        devshells.default = {
          packages = with pkgs; [
            cryptsetup
            zfs_unstable
            disko
            util-linux
            jq
            vim
          ];
          commands = lib.attrsets.mapAttrsToList (n: package: {inherit package;}) bin;
        };
        packages = bin;
      };
    };
}
