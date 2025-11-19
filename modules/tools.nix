{
  config,
  lib,
  ...
}:
let
  build_ip =
    arg:
    (
      if (!lib.strings.isString arg) then
        "${config.globals.ip_prefix}${toString arg}"
      else
        let
          id = config.id.${arg};
          ip = if (id > 1000) then id - 1000 else id;
        in
        "${config.globals.ip_prefix}${toString ip}"
    );
  build_ip_cidr = arg: "${build_ip arg}/${toString config.globals.cidr}";
  mask_cidr = build_ip_cidr 0;
  build_hostname = arg: "${arg}${config.globals.domains.external}";
  build_db_uri =
    container: base:
    let
      db_user = container;
      db_pass = config.my-lxc.${container}.db.password;
      db_host = build_ip "db";
      db_port = "5432";
      db_name = base;
    in
    "postgresql://${db_user}:${db_pass}@${db_host}:${db_port}/${db_name}";
in
{
  build_ip = build_ip;
  build_ip_cidr = build_ip_cidr;
  mask_cidr = mask_cidr;
  build_hostname = build_hostname;
  build_db_uri = build_db_uri;

  loki_addr = "${build_ip "monitoring"}:3100";
  metrics_addr = "${build_ip "metrics"}:9090";
}
