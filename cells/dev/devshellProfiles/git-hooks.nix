{
  pkgs,
  lib,
  inputs,
  ...
}: let
  inherit (inputs.std.data) configs;
  inherit (inputs.std.lib.dev) mkNixago;
in {
  nixago = [
    (mkNixago configs.lefthook {
      data = {};
    })
    (mkNixago configs.conform {
      data = {};
    })
  ];
}
