{ ... }:
{
  my-lxc.metrics = {
    container = {
      cores = 1;
      memory = 1024;
      disk = "10G";
      swap = 512;
    };
    system = {
      additionalPorts = [ 9090 ];
      importConfig = [
        ../config/metrics-prometheus.nix
      ];
    };
    logging = {
      enable = true;
      metricsEnable = true;
    };
    private = true;
    auth = true; # unused anyway
  };
}
