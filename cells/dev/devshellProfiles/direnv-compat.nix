/*
only $PRJ_ROOT and $PRJ_DATA_HOME is available in `std` when using `nix develop` (not using `direnv`):
    direnv: PRJ_ROOT:        /home/kdn/dev/github.com/nazarewk-iac/talos-configs
    direnv: PRJ_ID:          none
    direnv: PRJ_CONFIG_HOME: .config
    direnv: PRJ_RUNTIME_DIR: .run
    direnv: PRJ_CACHE_HOME:  .cache
    direnv: PRJ_DATA_HOME:   .data
    direnv: PRJ_PATH:        .bin

the 2 existing values come from:
  - PRJ_ROOT: https://github.com/numtide/devshell/blob/1ebbe68d57457c8cae98145410b164b5477761f4/modules/devshell.nix#L62-L72
  - PRJ_DATA_HOME: https://github.com/numtide/devshell/blob/1ebbe68d57457c8cae98145410b164b5477761f4/modules/env.nix#L119
*/
{
  pkgs,
  lib,
  ...
}: let
  default = name: value: {
    inherit name;
    eval = ''''${${name}:-"${value}"}'';
  };
in {
  env = lib.mkOrder 400 [
    (default "PRJ_CACHE_HOME" "$PRJ_ROOT/.cache")
    (default "PRJ_CONFIG_HOME" "$PRJ_ROOT/.config")
    (default "PRJ_DATA_HOME" "$PRJ_ROOT/.data")
    (default "PRJ_PATH" "$PRJ_ROOT/.bin")
    (default "PRJ_RUNTIME_DIR" "$PRJ_ROOT/.run")
    {
      name = "PATH";
      # note: this is not part of direnv
      eval = "$PRJ_PATH:$PATH";
    }
  ];
}
