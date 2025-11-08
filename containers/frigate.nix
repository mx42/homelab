{ ... }:
{
  my-lxc.frigate = {
    container = {
      cores = 4;
      memory = 2048;
      disk = "12G";
      swap = 1024;
    };
    system = {
      port = 80;
      importConfig = [
        ../config/frigate-frigate.nix
      ];
    };
    logging = {
      enable = true;
      metricsEnable = true;
    };
    private = false;
    auth = true;
  };
}
