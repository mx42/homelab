{
  config,
  tools,
  lib,
  ...
}:
let
  cfg = config.my-lxc;
in
{
  proxmox_lxc = lib.mapAttrs (
    name: def:
    let
      c = def.container;
    in
    lib.mkIf (c.enable) {
      hostname = name;
      memory = c.memory;
      cores = c.cores;
      ostemplate = "local:vztmpl/\${var.ostemplate}.tar.xz";
      unprivileged = true;
      password = "changeme";
      features.nesting = true;
      target_node = "\${var.pve_node}";
      network = {
        name = "eth0";
        bridge = "vmbr0";
        ip = tools.build_ip_cidr name;
        gw = config.globals.gateway;
        type = "veth";
      };
      protection = c.protection;
      onboot = true;
      rootfs = {
        storage = "local-lvm";
        size = c.disk;
      };
      swap = c.swap;
      vmid = config.id.${name};
      tags = lib.strings.join ";" ([ "terraform" ] ++ c.tags);
    }
    // c.overrides
  ) cfg;

}
