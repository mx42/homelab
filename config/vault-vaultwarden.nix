{
  pkgs,
  config,
  tools,
  ...
}:
let
  container = "vault";
  hostname = tools.build_hostname container;
  db_host = tools.build_ip "db";
  db_password = config.my-lxc.vault.db.password;
in
{
  services.vaultwarden = {
    enable = true;
    config = {
      DISABLE_ADMIN_TOKEN = true;
      ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_PORT = config.my-lxc.vault.system.port;
      DOMAIN = "https://${hostname}";
      SIGNUPS_ALLOWED = false;
      DATABASE_URL = "postgresql://${container}:${db_password}@${db_host}:5432/${container}";
      WEB_VAULT_ENABLED = true;
      INVITATIONS_ENABLED = true;
      ORG_CREATION_USERS = config.globals.master.email;
    };
    dbBackend = "postgresql";
  };
}
