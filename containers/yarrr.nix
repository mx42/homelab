{ ... }:
let
  db_pass = import ../config/_passwords.nix;
in
{
  my-lxc.yarrr = {
    container = {
      enable = false;
      cores = 4;
      memory = 2048;
      disk = "8G";
      swap = 512;
      protection = false;
    };
    db = {
      enable = true;
      password = db_pass.yarrr;
      additionalDB = [
        "yarrr_radarr"
        "yarrr_sonarr"
        "yarrr_readarr"
        "yarrr_lidarr"
      ];
    };
    system = {
      importConfig = [
        ../config/yarrr-arr.nix
      ];
    };
    logging = {
      enable = true;
      metricsEnable = true;
      prometheusPorts = {
        yarrr = 9708;
      };
    };
    otherDomains = [
      {
        subdomain = "bazarr";
        port = 6767;
      }
      {
        subdomain = "lidarr";
        port = 8686;
        auth = false;
      }
      {
        subdomain = "radarr";
        port = 7878;
      }
      {
        subdomain = "readarr";
        port = 8787;
      }
      {
        subdomain = "sonarr";
        port = 8989;
      }
      {
        subdomain = "prowlarr";
        port = 9696;
      }
    ];
  };
}
