{ config, tools, ... }:
let
  hostname = tools.build_hostname "frigate";
  mask_cidr = tools.mask_cidr;
  camera = tools.build_ip "camera";
  user = "admin"; # use yours
  pass = "admin"; # use yours
in
{
  services.frigate = {
    enable = true;
    hostname = hostname;
    checkConfig = false;
    settings = {
      auth = {
        trusted_proxies = [
          mask_cidr
        ];
      };
      proxy = {
        header_map = {
          user = "X-authentik-name";
          role = "X-authentik-groups";
        };
        separator = "|";
        default_role = "admin";
      };
      cameras = {
        front = {
          enabled = true;
          ffmpeg.inputs = [
            {
              # TODO: Move this elsewhere
              path = "rtsp://${user}:${pass}@${camera}:554/?streamtype=0&subtype=1";
              roles = [
                "audio"
                "detect"
                "record"
              ];
            }
          ];
          onvif = {
            host = camera;
            port = 8899;
            user = user;
            password = pass;
          };
        };
      };
    };
    # vaapiDriver ...
  };
}
