{
  pkgs,
  lib ? pkgs.lib,
  ...
}: let
  src = ./.;
  configs = {
    pwet-local = {
      zpool.name = "pic-local";
      lsblk.serial = "S676NL0W685078      ";
      luks.uuid = "25d5770e-0e58-41c9-b775-0f1e38fb4af9";
      disko = "${./local-storage.disko.lib.nix}";
    };
    turo-local = {
      zpool.name = "pic-local";
      lsblk.serial = "S676NL0W685083      ";
      luks.uuid = "9befac86-93ff-4cd0-a4f2-705855295654";
      disko = "${./local-storage.disko.lib.nix}";
    };
    yost-local = {
      zpool.name = "pic-local";
      lsblk.serial = "S676NL0W685081      ";
      luks.uuid = "48a8eb87-d273-40ab-ae63-f7e97a9ab5e9";
      disko = "${./local-storage.disko.lib.nix}";
    };
  };

  mkScript = args:
    lib.getExe (pkgs.writeShellApplication (args
      // {
        text = ''
          set -eEuo pipefail
          test -z "''${DEBUG:-}" || set -x
          ${args.text}
        '';
      }));

  mkDisks = builtins.mapAttrs (name: cfg: let
    bin.disko = mkScript {
      name = "disks-disko-${name}";
      runtimeInputs = with pkgs; [disko];
      text = ''
        if [[ "''${1:-}" == /dev/* ]] ; then
          device="$1"
          shift 1
        else
          device="$(${bin.search} --single)"
        fi
        disko \
          --argstr "device" "$device" \
          --argstr "name" "${lib.strings.toLower name}" \
          --argstr "poolName" "${lib.strings.toLower cfg.zpool.name}" \
          --argstr "luksUUID" "${cfg.luks.uuid}" \
          "$@" ${cfg.disko}
      '';
    };
    bin.render = mkScript {
      name = "disks-render-${name}";
      runtimeInputs = with pkgs; [];
      text = ''
        mode="''${mode:-"format"}"
        if test "$#" -gt 0 ; then
          mode="$1"
          shift 1
        fi
        script="$(${bin.disko} /dev/fake --dry-run --mode "$mode" "$@")"
        cat "$script"
      '';
    };
    bin.search = mkScript {
      name = "disks-search-${name}";
      runtimeInputs = with pkgs; [util-linux jq];
      text = ''
        export single=0
        case "''${1:-}" in
          --single)
            single=1
          ;;
        esac

        lsblk -OJ | jq -r '
          .blockdevices | map(select(contains(${builtins.toJSON cfg.lsblk})).path)
          | if env.single == "1" and length != 1 then error("required exactly one match, found: \(@json)") end
          | .[]
        '
      '';
    };
  in {
    inherit name cfg bin;
  });
in
  mkDisks configs
