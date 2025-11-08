{
  ...
}:
let
  db_pass = import ../config/_passwords.nix;
in
{
  my-lxc.finances = {
    container = {
      cores = 1;
      memory = 512;
      disk = "4G";
      swap = null;
    };
    system = {
      port = 80;
      importConfig = [
        ../config/finances-fireflyiii.nix
      ];
    };
    logging = {
      enable = true;
      metricsEnable = true;
    };
    db = {
      enable = true;
      password = db_pass.finances;
    };
    private = true;
    auth = true;
  };
}
