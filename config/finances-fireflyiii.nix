{
  config,
  tools,
  ...
}:
let
  name = "finances";
  hostname = tools.build_hostname name;
  ip = tools.build_ip name;
in
{
  services.firefly-iii = {
    enable = true;
    enableNginx = true;
    settings = {
      SITE_OWNER = config.globals.master.email;
      DB_CONNECTION = "pgsql";
      DB_HOST = ip;
      DB_PORT = 5432;
      DB_DATABASE = hostname;
      DB_USERNAME = hostname;
      DB_PASSWORD = config.my-lxc.finances.db.password;
      AUTHENTICATION_GUARD = "remote_user_guard";
      AUTHENTICATION_GUARD_HEADER = "HTTP_REMOTE_EMAIL";
      AUTHENTICATION_GUARD_EMAIL = "HTTP_REMOTE_EMAIL";
      APP_KEY_FILE = config.age.secrets.finances-app-key.path;
    };
  };
}
