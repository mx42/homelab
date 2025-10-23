{
  infra,
  ip,
  domainname,
  ...
}:
{
  enable = true;
  host = "0.0.0.0";
  port = 80;
  openFirewall = true;
  mutableSettings = true;
  settings = {
    http = {
      address = "${ip}:80";
      session_ttl = "720h";
    };
    users = [
      {
        name = infra.master_login;
        password = infra.master_htpasswd;
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
      bind_hosts = [ ip ];
      port = 53;
      upstream_dns = [
        "127.0.0.1:5335"
        "https://dns10.quad9.net/dns-query"
      ];
    };
    filtering = {
      safe_search = {
        enabled = true;
        bing = true;
        duckduckgo = true;
        ecosia = true;
        google = true;
        pixabay = true;
        yandex = true;
        youtube = true;
      };
      rewrites = [
        {
          domain = "*${infra.domains.exposed}";
          answer = infra.reverse_proxy_addr;
        }
        {
          domain = domainname;
          answer = ip;
        }
        # add internal domains for all containers?
      ];
    };
  };
}
