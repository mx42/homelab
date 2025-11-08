{ pkgs, ... }:
let
  lib = pkgs.lib;

  containersFiles = builtins.readDir ./.;
  containers = lib.filter (v: v != null) (
    (lib.mapAttrsToList (
      name: type:
      if type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name then ./${name} else null
    ))
      containersFiles
  );
in
containers
