{ config, lib, ... }:
let
  cfg = config.my-lxc;
in
{
  postgresql_role = lib.filterAttrs (_: v: v != { }) (
    lib.mapAttrs (
      containerName: def:
      lib.optionalAttrs (def.db.enable) {
        name = containerName;
        login = true;
        password = def.db.password;
      }
    ) cfg
  );
  postgresql_database = lib.foldl' (acc: elem: acc // elem) { } (
    lib.mapAttrsToList (
      containerName: def:
      lib.optionalAttrs (def.db.enable) (
        # mkIf ?
        lib.listToAttrs (
          lib.map (db: {
            name = db;
            value = {
              name = db;
              owner = containerName;
              lc_ctype = "C";
              lc_collate = "C";
            };
          }) (def.db.additionalDB ++ [ containerName ])
        )
      )
    ) cfg
  );
}
