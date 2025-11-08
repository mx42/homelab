{
  ...
}:
let
  db_pass = import ../config/_passwords.nix;
in
{
  my-lxc.matrix = {
    container = {
      cores = 2;
      memory = 2048;
      disk = "4G";
      swap = 512;
    };
    system = {
      additionalPorts = [
        80
        8008
        8080
        5173
      ];
      importConfig = [
        ../config/matrix-synapse.nix
        ../config/matrix-mas.nix
        ../config/matrix-nginx.nix
      ];
    };
    db = {
      enable = true;
      password = db_pass.matrix;
      additionalDB = [
        "matrix_mas"
      ];
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
        subdomain = "matrix";
        port = 8008;
        private = false;
        auth = false;
        customRule = "Host(`matrix#DOMAIN#`) && !(PathPrefix(`/_matrix/client/*/login`) || PathPrefix(`/_matrix/client/*/logout`) || PathPrefix(`/_matrix/client/*/refresh`))";
      }
      {
        subdomain = "matrix_auth";
        port = 8080;
        private = false;
        auth = false;
        customRule = "Host(`matrix#DOMAIN#`) && (PathPrefix(`/_matrix/client/*/login`) || PathPrefix(`/_matrix/client/*/logout`) || PathPrefix(`/_matrix/client/*/refresh`))";
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
