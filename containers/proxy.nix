{ ... }:
{
  my-lxc.proxy = {
    container = {
      cores = 2;
      memory = 512;
      disk = "5G";
      swap = 512;
    };
    system = {
      port = 8080;
      additionalPorts = [
        80
        443
        8082
      ];
      udpPorts = [ 443 ];
      importConfig = [
        ../config/proxy-traefik.nix
      ];
    };
    logging = {
      enable = true;
      metricsEnable = true;
      prometheusPorts.traefik = 8082;
      journalLoggers.traefik = ''
        stage.regex {
          expression = "^(?P<client_ip>\\S+) (?P<ident>\\S+) (?P<auth_id>\\S+) \\[(?P<timestamp>[^\\]]+)\\] \"(?P<method>\\S+) (?P<path>\\S+) HTTP/(?P<http_version>\\S+)\" (?P<status>\\d+) (?P<bytes_sent>\\d+) \"(?P<referrer>[^\"]*)\" \"(?P<user_agent>[^\"]*)\" (?P<bytes_received>\\d+) \"(?P<router>[^\"]*)\" \"(?P<upstream>[^\"]*)\" (?P<duration>\\d+)ms$"
        }

        stage.timestamp {
          source = "timestamp"
          format = "02/Jan/2006:15:04:05 -0700"
        }

        stage.labels {
        values = {
          client_ip = "",
          ident = "",
          auth_id = "",
          method = "",
          status = "",
          referrer = "",
          router = "",
          upstream = "",
          }
        }
      '';
    };
    private = true;
    auth = true;
  };
}
