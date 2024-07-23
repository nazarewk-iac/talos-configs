{
  pkgs,
  lib ? pkgs.lib,
  ...
}: let
  src = ./.;
  configs = {
    #hurl-local = {
    #  zpool.name = "pic-local";
    #  lsblk = lsblk.crucialBX5001TBThroughBay;
    #  luks.uuid = "6e1fb50e-adab-4cdd-96f8-b0f698c29a4f";
    #  disko = "${./local-storage.disko.lib.nix}";
    #};
    #jhal-local = {
    #  zpool.name = "pic-local";
    #  lsblk = lsblk.crucialBX5001TBThroughBay;
    #  luks.uuid = "f96cf5d6-bf04-4897-87c4-fc8f13585fb7";
    #  disko = "${./local-storage.disko.lib.nix}";
    #};
    #rant-local = {
    #  zpool.name = "pic-local";
    #  lsblk = lsblk.crucialBX5001TBThroughBay;
    #  luks.uuid = "5d43c8c0-ad3e-4165-bb1a-ea8a4fdadf45";
    #  disko = "${./local-storage.disko.lib.nix}";
    #};
  };

  lsblk.crucialBX5001TBThroughBay = {
    model = "500SSD1         ";
    rev = "0520";
    size = "931.5G";
    vendor = "CT1000BX";
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
