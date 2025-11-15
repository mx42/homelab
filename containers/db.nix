{ ... }:
{
  my-lxc.db = {
    container = {
      cores = 2;
      memory = 2048;
      disk = "16G";
      swap = 512;
    };
    system = {
      additionalPorts = [
        9187
        5432
      ];
      importConfig = [
        ../config/db-postgres.nix
      ];
      services.prometheus.exporters.postgres = {
        enable = true;
        listenAddress = "0.0.0.0";
        port = 9187;
      };
    };
    logging = {
      enable = true;
      metricsEnable = true;
      prometheusPorts = {
        postgres = 9187;
      };
    };
    private = true;
    auth = true;
    otherDomains = [
      {
        subdomain = "db";
        port = 5432;
        private = true;
        auth = false;
        raw_tcp = true;
      }
    ];
  };
}
