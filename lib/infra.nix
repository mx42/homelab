{ lib, ... }:
{
  terraform.required_providers = {
    proxmox = {
      source = "Telmate/proxmox";
      version = "~> 2.9.11";
    };
  };

  provider.proxmox = {
    pm_api_url = "\${var.pm_api_url}";
    pm_api_token_id = "\${var.pm_api_token_id}";
    pm_api_token_secret = "\${var.pm_api_token_secret}";
    pm_tls_insecure = false;
  };

  variable.pm_api_url.type = "string";
  variable.pm_api_token_id.type = "string";
  variable.pm_api_token_secret.type = "string";
  variable.pve_node.type = "string";
}
