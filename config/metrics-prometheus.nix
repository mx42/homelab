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
      "--storage.tsdb.retention.time=${config.globals.retention}"
    ];
    exporters.pve = {
      enable = true;
      collectors = {
        cluster = true;
        config = false;
        node = true;
        replication = false;
        resources = true;
        status = true;
        version = true;
      };
      configFile = config.age.secrets.metrics-pve.path;
      port = 9221;
    };
    globalConfig = {
      scrape_interval = "30s";
    };
    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [
          {
            targets = [ "localhost:9090" ];
            labels = {
              host = tools.build_hostname "metrics";
              host_ip = tools.build_ip "metrics";
              service = "prometheus";
            };
          }
        ];
      }
      {
        job_name = "proxmox";
        static_configs = [
          {
            targets = [ "localhost:9221" ];
            labels = {
              host = tools.build_hostname "proxmox";
              host_ip = tools.build_ip "proxmox";
              service = "proxmox";
            };
          }
        ];
        metrics_path = "/pve";
        params = {
          target = [ (tools.build_ip "proxmox") ];
        };
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
          static_configs = lib.mapAttrsToList (service: port: {
            targets = [ "${container_ip}:${toString port}" ];
            labels = {
              host = tools.build_hostname container;
              host_ip = tools.build_ip container;
              service = service;
            };
          }) def.logging.prometheusPorts;
        }
      ) config.my-lxc
    ));
  };
}
