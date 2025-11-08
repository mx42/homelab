{ ... }:
{
  my-lxc.grocy = {
    container = {
      cores = 1;
      memory = 512;
      disk = "4G";
      swap = 512;
    };
    system = {
      port = 80;
      importConfig = [
        ../config/grocy-grocy.nix
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
