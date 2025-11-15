{
  config,
  tools,
  pkgs,
  ...
}:
let
  lib = pkgs.lib;
  master_login = config.globals.master.login;
  master_pass = config.globals.master.initial_htpasswd;
  ip = tools.build_ip;
  proxy_addr = ip "proxy";
  domain_ext = config.globals.domains.external;
  domain_int = config.globals.domains.internal;
in
{
  environment.etc."alloy/logs-adguardhome.alloy".text =
    (import ./alloy/default-journal-logger.alloy.nix {
      inherit tools;
      container = "dns";
      service = "adguardhome";
      additional_stages = ''
        stage.regex {
          expression = "^(?P<timestamp>\\S+ \\S+) \\[(?P<level>\\w+)\\] (?P<message>.*)$"
        }

        stage.timestamp {
          source = "timestamp"
          format = "2006/01/02 15:04:05.999999"
          location = "${config.globals.default_tz}"
        }

        stage.labels {
          values = {
            level = "level",
          }
        }

        stage.output {
          source = "message"
        }
      '';
    }).out;
  services.adguardhome = {
    enable = true;
    host = "0.0.0.0";
    port = 80;
    openFirewall = true;
    mutableSettings = true; # ??
    settings = {
      http = {
        address = "0.0.0.0:80";
        session_ttl = "720h";
      };
      users = [
        {
          name = master_login;
          password = master_pass;
        }
      ];
      filters = [
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          name = "AdGuard DNS filter";
          id = 1;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
          name = "AdAway Default Blocklist";
          id = 2;
        }
      ];

      auth_attempts = 5;
      block_auth_min = 15;
      language = "fr";
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        upstream_dns = [
          "127.0.0.1:5335"
          "https://dns10.quad9.net/dns-query"
        ];
        trusted_proxies = [
          "127.0.0.0/8"
          "::1/128"
          proxy_addr
        ];
      };
      filtering = {
        safe_search.enabled = false;
        blocking_mode = "nxdomain";
        rewrites = [
          {
            domain = "*${domain_ext}";
            answer = proxy_addr;
          }
        ]
        ++ (lib.mapAttrsToList (d: id: {
          domain = "${d}${domain_int}";
          answer = "${ip d}";
        }) config.id);
      };
    };
  };
}
