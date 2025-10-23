{ container_id, ... }:
let
  infra = import ../../constants.nix;
in
{
  out = ''
    prometheus.exporter.unix "default" {
      include_exporter_metrics = true
      disable_collectors       = ["mdadm"]
    }

    prometheus.scrape "default" {
      targets = array.concat(
        prometheus.exporter.unix.default.targets,
        [{
          // Self-collect metrics
          job         = "alloy",
          __address__ = "127.0.0.1:12345",
        }],
      )

      forward_to = [prometheus.relabel.filter_metrics.receiver]
      scrape_interval = "60s"
    }

    prometheus.relabel "filter_metrics" {
      rule {
        action = "drop"
        source_labels = [ "env" ]
        regex = "dev"
      }
      rule {
        action = "replace"
        regex = "127\\.0\\.0\\.1"
        target_label = "instance"
        replacement = "${infra.build_ip container_id}"
      }
      forward_to = [prometheus.remote_write.metrics_service.receiver]
    }

    prometheus.remote_write "metrics_service" {
      endpoint {
        url = "http://${infra.prometheus_addr}/api/v1/write"
      }
    }
  '';
}
