{ ... }:
{
  my-lxc.proxy = {
    container = {
      cores = 2;
      memory = 512;
      disk = "5G";
      swap = 512;
    };
    system = {
      port = 8080;
      additionalPorts = [
        80
        443
        8082
      ];
      udpPorts = [ 443 ];
      importConfig = [
        ../config/proxy-traefik.nix
      ];
    };
    logging = {
      enable = true;
      metricsEnable = true;
      alloyConfig = {
        # probably move to default-journal...
        "logs-traefik" = ../config/alloy/proxy-traefik.alloy.nix;
      };
    };
    private = true;
    auth = true;
  };
}
