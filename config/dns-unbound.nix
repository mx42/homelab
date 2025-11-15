{
  config,
  tools,
  ...
}:
let
  mask_cidr = tools.mask_cidr; # build_ip_cidr 0 config.globals.cidr;
in
{
  environment.etc."alloy/logs-unbound.alloy".text =
    (import ./alloy/default-journal-logger.alloy.nix {
      inherit tools;
      container = "dns";
      service = "unbound";
      additional_stages = ''
        stage.pattern {
          pattern = "[<_>] <level>: <message>"
        }

        stage.labels {
          values = {
            level = "level",
          }
        }

        stage.output {
          source = "message"
        }
      '';
    }).out;
  services.prometheus.exporters.unbound = {
    enable = true;
    port = 9167;
    openFirewall = true;
  };
  services.unbound = {
    enable = true;
    settings = {
      remote-control = {
        control-enable = true;
        control-interface = "/run/unbound/unbound.ctl";
      };
      server = {
        auto-trust-anchor-file = "/var/lib/unbound/root.key";
        interface = "0.0.0.0";
        port = "5335";
        hide-identity = true;
        hide-version = true;
        harden-referral-path = true;
        cache-min-ttl = 300;
        cache-max-ttl = 14400;
        serve-expired = true;
        serve-expired-ttl = 3600;
        prefetch = true;
        prefetch-key = true;
        private-address = [
          mask_cidr
        ];
        do-ip6 = false;
        so-sndbuf = 0;
        access-control = [
          "${mask_cidr} allow"
          "127.0.0.1/32 allow"
        ];
      };
    };
  };
}
