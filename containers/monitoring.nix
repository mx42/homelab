{ ... }:
let
  db_pass = import ../config/_passwords.nix;
in
{
  my-lxc.monitoring = {
    container = {
      cores = 2;
      memory = 1024;
      disk = "10G";
      swap = 512;
    };
    system = {
      port = 3000; # grafana
      additionalPorts = [
        3100 # loki
      ];
      importConfig = [
        ../config/monitoring-grafana.nix
        ../config/monitoring-loki.nix
      ];
    };
    db = {
      enable = true;
      password = db_pass.monitoring;
    };
    logging = {
      enable = true;
      metricsEnable = true;
    };
    private = true;
    auth = true;
  };
}
