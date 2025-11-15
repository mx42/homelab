{
  ...
}:
let
  db_pass = import ../config/_passwords.nix;
in
{
  my-lxc.matrix = {
    container = {
      enable = true;
      cores = 2;
      memory = 2048;
      disk = "6G";
      swap = 512;
    };
    system = {
      port = 8008; # -> synapse
      additionalPorts = [
        80 # element web
        5173 # synapse admin
      ];
      importConfig = [
        ../config/matrix-synapse.nix
        ../config/matrix-nginx.nix
      ];
    };
    db = {
      enable = true;
      password = db_pass.matrix;
    };
    logging = {
      enable = true;
      metricsEnable = true;
    };
    private = false;
    auth = false;
    otherDomains = [
      {
        subdomain = "chat";
        port = 80;
        private = false;
        auth = false;
      }
      {
        subdomain = "matrix-admin";
        port = 5173;
        private = true;
        auth = false;
      }
    ];
  };
}
