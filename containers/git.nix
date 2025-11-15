{ ... }:
let
  db_pass = import ../config/_passwords.nix;
in
{
  my-lxc.git = {
    container = {
      cores = 1;
      memory = 2048;
      disk = "10G";
      swap = 512;
    };
    db = {
      enable = true;
      password = db_pass.git;
    };
    system = {
      port = 3000;
      importConfig = [
        ../config/git-gitea.nix
      ];
    };
    logging = {
      enable = true;
      metricsEnable = true;
    };
    private = false; # available only on private lan
    auth = false; # auth overlay
  };
}
