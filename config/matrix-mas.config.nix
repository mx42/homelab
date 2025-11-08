{ config, tools, ... }:
let
  mask = tools.mask_cidr;
  db_host = tools.build_ip "db";
  db_pass = (import ../config/_passwords.nix).matrix;

  hostname = tools.build_hostname "matrix";
  auth = tools.build_hostname "auth";
  sec = import ../config/_matrix_secrets.nix;
in
{
  http = {
    listeners = [
      {
        name = "web";
        resources = [
          { name = "discovery"; }
          { name = "human"; }
          { name = "oauth"; }
          { name = "compat"; }
          { name = "graphql"; }
          { name = "assets"; }
        ];
        binds = [
          { address = "[::]:8080"; }
        ];
        proxy_protocol = false;
      }
      {
        name = "internal";
        resources = [
          { name = "health"; }
        ];
        binds = [
          {
            host = "localhost";
            port = 8081;
          }
        ];
        proxy_protocol = false;
      }
    ];
    trusted_proxies = [
      mask
      "127.0.0.1/8"
    ];
    public_base = "http://[::]:8080/";
    issuer = "http://[::]:8080/";
    database = {
      uri = "postgresql://matrix:${db_pass}@${db_host}:5432/matrix_mas";
      max_connections = 10;
      min_connections = 0;
      connect_timeout = 30;
      idle_timeout = 600;
      max_lifetime = 1800;
    };
    email = {
      from = "\"Authentication Service\" <root@localhost>";
      reply_to = "\"Authentication Service\" <root@localhost>";
      transport = "blackhole";
    };
    secrets = sec.mas;
    passwords = {
      enabled = true;
      schemes = [
        {
          version = 1;
          algorithm = "bcrypt";
          minimum_complexity = 3;
        }
      ];
    };
    matrix = {
      kind = "synapse";
      homeserver = hostname;
      secret = sec.mas_secret;
      endpoint = "http://localhost:8008/";
      upstream_oauth2 = {
        providers = [
          {
            id = sec.oidc_provider_id;
            synapse_idp_id = "oidc-authentik";
            issuer = "https://${auth}";
            client_id = sec.oidc_client_id;
            client_secret = sec.oidc_client_secret;
            scope = "openid profile email";
            discovery_mode = "insecure";
            claims_imports = {
              localpart = {
                action = "require";
                template = "{{ user.preferred_username }}";
                on_conflicts = "add";
              };
              displayname = {
                action = "suggest";
                template = "{{ user.name }}";
              };
            };
          }
        ];
      };
    };
  };
}
