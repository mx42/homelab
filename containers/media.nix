{ ... }:
let
  db_pass = import ../config/_passwords.nix;
in
{
  my-lxc.media = {
    container = {
      cores = 4;
      memory = 4096;
      disk = "12G";
      swap = 1024;
    };
    db = {
      enable = true;
      password = db_pass.media;
    };
    system = {
      port = 8096; # jellyfin default http
      additionalPorts = [ 5055 ]; # jellyseerr default
      services = {
        jellyfin = {
          enable = true;
          openFirewall = true;
          # TODO: Manual bind-mount in proxmox
          dataDir = "/mnt/nas/app-data/jellyfin";
          logDir = "/var/log/jellyfin";
          user = "root";
          group = "root";
        };
        jellyseerr = {
          enable = true;
          openFirewall = true;
          # TODO: Same...
          configDir = "/mnt/nas/app-data/jellyseerr";
        };
      };
    };
    logging = {
      enable = true;
      metricsEnable = true;
    };
    private = true;
    auth = true;
    otherDomains = [
      {
        subdomain = "flix";
        port = 5055;
        private = true;
        auth = true;
      }
    ];
  };
}
