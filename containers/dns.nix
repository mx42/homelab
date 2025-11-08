{
  ...
}:
{
  my-lxc.dns = {
    container = {
      cores = 2;
      memory = 1024;
      disk = "4G";
      swap = 512;
    };
    system = {
      port = 80;
      additionalPorts = [
        53
      ];
      udpPorts = [ 53 ];
      importConfig = [
        ../config/dns-adguardhome.nix
        ../config/dns-unbound.nix
      ];
      services.resolved.enable = false;
    };
    logging = {
      enable = true;
      metricsEnable = true;
    };
    private = true;
    auth = true;
  };
}
