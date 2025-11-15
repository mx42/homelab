{
  ...
}:
{
  my-lxc.dns = {
    container = {
      cores = 2;
      memory = 1024;
      disk = "5G";
      swap = 768;
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
      prometheusPorts = [
        9167
      ];
    };
    private = true;
    auth = true;
  };
}
