{
  pkgs,
  name,
  containersMapping,
  ...
}:
let
  hostname = pkgs.lib.removeSuffix ".nix" name;
  infra = import ../lib/constants.nix;
  container_id = containersMapping.${hostname};
  ip = infra.build_ip container_id;
  domainname = "${hostname}${infra.domains.internal}";
in
{
  cores = 2;
  memory = "2G";
  disk = "4G";
  swap = 512;
  ports = [
    80
    53
    12345
  ];
  exposed = false;
  services = {
    adguardhome = import ./dns/adguardhome-config.nix { inherit infra ip domainname; };
    unbound = {
      enable = true;
    };
  };
  logging.enable = true;
  logging.metrics.enable = true;
  etc."alloy/logs-adguard.alloy".text =
    (import ./dns/logs-adguard.alloy.nix {
      inherit ip domainname;
    }).out;
  etc."alloy/logs-unbound.alloy".text =
    (import ./dns/logs-unbound.alloy.nix {
      inherit ip domainname;
    }).out;
}
