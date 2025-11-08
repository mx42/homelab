{ ... }:
let
  db_pass = import ../config/_passwords.nix;
in
{
  my-lxc.vault = {
    container = {
      cores = 1;
      memory = 512;
      disk = "4G";
      swap = 512;
    };
    db = {
      enable = true;
      password = db_pass.vault;
    };
    system = {
      port = 8000;
      importConfig = [
        ../config/vault-vaultwarden.nix
      ];
    };
    logging = {
      enable = true;
      metricsEnable = true;
    };
    private = false;
    auth = false;
  };
}
