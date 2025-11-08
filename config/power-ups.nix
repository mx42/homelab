{
  pkgs,
  config,
  tools,
  ...
}:
{
  power.ups = {
    enable = true;
    mode = "standalone";
    openFirewall = true; # -> 80
    ups.eaton5e = {
      driver = "usbhid-ups";
      port = "auto";
      summary = ''
        vendorid = "0463"
        productid = "FFFF"
        product = "Eaton 5E"
        serial = "BLANK"
        vendor = "EATON"
        bus = "002"
      '';
    };
    upsmon = {
      monitor.eaton5e = {
        user = "nut";
        powerValue = 1;
        system = "eaton5e";
      };
    };
    users.nut = {
      passwordFile = config.age.secrets.power-password-file.path;
      actions = [ "SET" ];
      instcmds = [ "ALL" ];
    };
  };
}
