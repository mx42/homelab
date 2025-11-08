{ ... }:
let
  db_pass = import ../config/_passwords.nix;
in
{
  my-lxc.auth = {
    container = {
      cores = 2;
      memory = 1024;
      disk = "8G";
      swap = 1024;
    };
    system = {
      port = 80;
      additionalPorts = [
        443
        389
        636
        9000
        9443
        3389
        6636
        9300
        9303
      ];
      udpPorts = [
        1812
      ];
      importConfig = [
        ../config/auth-authentik.nix
      ];
    };
    logging = {
      enable = true;
      metricsEnable = true;
    };
    db = {
      enable = true;
      password = db_pass.auth;
    };
    private = false;
    auth = false;
  };
}
