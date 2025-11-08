{
  config,
  tools,
  pkgs,
  ...
}:
let
  lib = pkgs.lib;
in
{
  services.prometheus = {
    enable = true;
    extraFlags = [
      "--web.enable-otlp-receiver"
      "--web.enable-remote-write-receiver"
    ];
    globalConfig = {
      scrape_interval = "30s";
    };
    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [
          { targets = [ "localhost:9090" ]; }
        ];
      }
    ]
    ++ (lib.filter (sc: sc.static_configs != [ ]) (
      lib.mapAttrsToList (
        container: def:
        let
          container_ip = tools.build_ip container;
        in
        {
          job_name = container;
          static_configs = map (port: {
            targets = [ "${container_ip}:${toString port}" ];
          }) def.logging.prometheusPorts;
        }
      ) config.my-lxc
    ));
  };
}
