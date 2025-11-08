{ tools, config, ... }:
let
  hostname = tools.build_hostname "auth";
in
{
  # Doesn't seem to like having the path directly in the params below?!
  environment.etc = {
    "authentik/ldap-secrets.env".source = config.age.secrets.auth-authentik-ldap-secrets.path;
    "authentik/proxy-secrets.env".source = config.age.secrets.auth-authentik-proxy-secrets.path;
    "authentik/secrets.env".source = config.age.secrets.auth-authentik-secrets.path;
  };
  services = {
    authentik = {
      enable = true;
      environmentFile = "/etc/authentik/secrets.env";
      nginx = {
        enable = true;
        host = hostname;
      };
    };
    authentik-ldap = {
      enable = true;
      environmentFile = "/etc/authentik/ldap-secrets.env";
    };
    authentik-proxy = {
      enable = true;
      environmentFile = "/etc/authentik/proxy-secrets.env";
    };
  };
}
