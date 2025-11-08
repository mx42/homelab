{ lib, ... }:
{
  terraform.required_providers = {
    proxmox = {
      source = "Telmate/proxmox";
      version = "~> 2.9.11";
    };

    postgresql = {
      source = "cyrilgdn/postgresql";
      version = "~> 1.26.0";
    };
  };

  provider.proxmox = {
    pm_api_url = "\${var.pm_api_url}";
    pm_api_token_id = "\${var.pm_api_token_id}";
    pm_api_token_secret = "\${var.pm_api_token_secret}";
    pm_tls_insecure = "\${var.pm_tls_insecure}";
  };

  variable.pm_api_url.type = "string";
  variable.pm_api_token_id.type = "string";
  variable.pm_api_token_secret.type = "string";
  variable.pm_tls_insecure.type = "bool";
  variable.pve_node.type = "string";
  variable.ostemplate.type = "string";

  provider.postgresql = {
    host = "\${var.pg_host}";
    port = 5432;
    database = "postgres";
    username = "\${var.pg_user}";
    password = "\${var.pg_pass}";
    sslmode = "disable";
    connect_timeout = 15;
  };

  variable.pg_host.type = "string";
  variable.pg_user.type = "string";
  variable.pg_pass.type = "string";
}
