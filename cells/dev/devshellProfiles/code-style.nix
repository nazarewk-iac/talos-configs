{
  pkgs,
  lib,
  inputs,
  ...
}: let
  inherit (inputs.std.data) configs;
  inherit (inputs.std.lib.dev) mkNixago;
  inherit (inputs.std.inputs) dmerge;
in {
  nixago = [
    (mkNixago configs.treefmt {
      data = {
        formatter.shell.includes = dmerge.append ["bin/talos*"];
      };
    })
    (mkNixago configs.editorconfig {
      data = {};
    })
  ];
}
