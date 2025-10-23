{ def, lib, ... }:
let
  infra = import ./constants.nix;

  hostname = def.hostname;
  memory = def.memory or 512;
  cores = def.cores or 1;
  container_id = def.container_id;
  disk = def.disk or "4G";
  swap = def.swap or 512;
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
  additional_tf_modules = def.additional_tf_modules or [ ];
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
    swap = swap;
    vmid = container_id;
    tags = "terraform;${tags}";
  }; # // each additional_tf_modules ?

  nixosModule =
    { config, pkgs, ... }:
    {
      imports = [
        ./lxc-template.nix
      ]
      ++ extraModules;
      networking.hostName = hostname;
      networking.firewall.allowedTCPPorts = open_ports;
      services =
        services
        // lib.optionalAttrs (logging_enabled) {
          alloy = {
            enable = true;
            extraFlags = [
              "--server.http.listen-addr=0.0.0.0:12345"
              "--disable-reporting"
            ];
          };
        };
      environment.etc =
        etc
        // lib.optionalAttrs (logging_enabled) {
          "alloy/config.alloy".text = (import ./config/alloy/config.alloy.nix).out;
          "alloy/metrics.alloy".text =
            if (logging_metrics_enabled) then
              (import ./config/alloy/metrics.alloy.nix { inherit container_id; }).out
            else
              "";
        };
      environment.systemPackages = other_packages;
    };
}
