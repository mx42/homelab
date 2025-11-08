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
in
{
  build_ip = build_ip;
  build_ip_cidr = build_ip_cidr;
  mask_cidr = mask_cidr;
  build_hostname = build_hostname;

  loki_addr = "${build_ip "monitoring"}:3100";
  metrics_addr = "${build_ip "metrics"}:9090";
}
