{ ... }:
{
  # TODO: Manual bind-mount /dev/bus/usb/{bus}/{device} # check with lsusb
  my-lxc.power = {
    container = {
      cores = 1;
      memory = 512;
      disk = "4G";
      swap = 512;
    };
    system = {
      importConfig = [
        ../config/power-ups.nix
      ];
    };
    logging = {
      enable = true;
      metricsEnable = true;
    };
    private = true;
    auth = true;
  };
}
