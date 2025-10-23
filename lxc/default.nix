{ pkgs, containersMapping, ... }:
let
  lib = pkgs.lib;

  containerBuild = import ../lib/container_build.nix;

  containersFiles = builtins.readDir ./.;

  containers = lib.filterAttrs (_: v: v != null) (
    lib.mapAttrs (
      name: type:
      if type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name then
        import ./${name} { inherit name containersMapping pkgs; }
      else
        null
    ) containersFiles
  );

  cleanedName = lib.listToAttrs (lib.mapAttrsToList (name: def: mkContainer name def) containers);

  mkContainer =
    name: raw_def:
    let
      hostname = lib.removeSuffix ".nix" name;
      def = raw_def // {
        hostname = hostname;
        container_id = containersMapping.${hostname};
      };
      result = containerBuild { inherit def lib; };
    in
    {
      name = hostname;
      value = result;
    };
in
cleanedName
