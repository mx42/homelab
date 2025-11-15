{
  config,
  tools,
  pkgs,
  ...
}:
let
  container = "matrix";
  hostname = tools.build_hostname container;
  admin_handle = "@${config.globals.master.login}:${hostname}";
  db_host = tools.build_ip "db";
  auth_host = tools.build_hostname "auth";
  db_pass = config.my-lxc.matrix.db.password;
  sec = import ../config/_matrix_secrets.nix;
in
{
  environment = {
    etc."alloy/logs-synapse.alloy".text =
      (import ./alloy/default-journal-logger.alloy.nix {
        inherit tools container;
        service = "matrix-synapse";
        additional_stages = ''
          stage.regex {
            expression = "^(?P<facility>\\S+): \\[(?P<worker>[^\\]]+)\\] (?P<message>.*)$"
          }
          stage.labels {
            values = {
              facility = "",
              worker = "",
            }
          }
          stage.output {
            source = "message"
          }
        '';
      }).out;
  };
  services.matrix-synapse = {
    enable = true;
    extras = [
      "jwt"
      "oidc"
      "postgres"
      "systemd"
      # "url-preview"
    ];
    # plugins matrix-synapse-ldap3?
    settings = {
      admin_users = [
        admin_handle
      ];
      enable_metrics = true;
      server_name = hostname;
      database = {
        name = "psycopg2";
        args = {
          user = container;
          password = db_pass;
          database = container;
          host = db_host;
          port = 5432;
          cp_min = 5;
          cp_max = 10;
        };
        allow_unsafe_locale = true;
      };
      listeners = [
        {
          bind_addresses = [ "0.0.0.0" ];
          port = 8008;
          resources = [
            {
              compress = true;
              names = [ "client" ];
            }
            {
              compress = false;
              names = [ "federation" ];
            }
          ];
          tls = false;
          type = "http";
          x_forwarded = true;
        }
      ];
      # matrix-authentication-service = {
      #   enable = true;
      #   endpoint = "http://localhost:8080/";
      #   secret = sec.mas_secret;
      # };
      jwt_config = {
        enabled = true;
        secret = sec.jwt_secret;
        algorithm = sec.jwt_algo;
      };
      oidc_providers = [
        {
          idp_id = "authentik";
          idp_name = "authentik";
          discover = true;
          issuer = "https://${auth_host}/application/o/chat/";
          client_id = sec.oidc_client_id;
          client_secret = sec.oidc_client_secret;
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          user_mapping_provider.config = {
            localpart_template = "{{ user.preferred_username }}";
            display_name_template = "{{ user.name }}";
          };
        }
      ];
      macaroon_secret_key = sec.macaroon;
      suppress_key_server_warning = true;
    };
  };
}
