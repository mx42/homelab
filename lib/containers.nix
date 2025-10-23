{ def, ... }:
let
  infra = import ../infra/constants.nix;

  hostname = def.hostname;
  memory = def.memory or 512;
  cores = def.cores or 1;
  container_id = def.container_id;
  disk = def.disk or "4G";
  swap = def.swap or null; # TODO: Implement
  services = def.services or { };
  open_ports = def.open_ports or [ ];
  other_packages = def.other_packages or [ ];
  etc = def.etc or { };
  logging_enabled = def.logging.enable or false; # TODO: Implement
  logging_metrics_enabled = def.logging.metrics.enable or false;
  extraModules = def.extraModules or [ ];
  template = def.template or infra.nixos_template_name;
  unprivileged = def.unprivileged or true;
  tags = def.tags or "";
in
{
  terraformResource = {
    hostname = hostname;
    memory = memory;
    cores = cores;
    ostemplate = "local:vztmpl/${template}.tar.xz";
    unprivileged = unprivileged;
    password = "changeme";
    features.nesting = true;
    target_node = "\${var.pve_node}";
    network = {
      name = "eth0";
      bridge = "vmbr0";
      ip = infra.build_ip_cidr container_id;
      gw = infra.gateway_ip;
      type = "veth";
    };
    rootfs = {
      storage = "local-lvm";
      size = disk;
    };
    vmid = container_id;
    tags = "terraform;${tags}";
  };

  nixosModule =
    { config, pkgs, ... }:
    {
      imports = [
        ../infra/lxc-template.nix
      ]
      ++ extraModules;
      networking.hostName = hostname;
      networking.firewall.allowedTCPPorts = open_ports;
      services = services;
      environment.etc = etc;
      environment.systemPackages = other_packages;
      # logging things...
      #     # logs configuration ...
      #     # environment.etc."alloy/config.alloy" = '' loki blabla '';
      #     # environment.etc."alloy/metrics.alloy" = '' prometheus blabla '';
      #     #
      #     # -> services.alloy.extraFlags = [
      #     #   "--server.http.listen-addr=127.0.0.1:12346"
      #     #   "--disable-reporting"
      #     # ]
    };
}
