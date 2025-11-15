{
  config,
  tools,
  container,
  ...
}:
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
        source_labels = ["__name__"]
        regex         = ".*_build_info"
        action        = "drop"
      }
      rule {
        source_labels = ["__name__"]
        regex         = "go_.*"
        action        = "drop"
      }
      rule {
        source_labels = [ "env" ]
        regex         = "dev"
        action        = "drop"
      }
      rule {
        target_label  = "host"
        replacement   = "${tools.build_hostname container}"
      }
      rule {
        target_label  = "host_ip"
        replacement   = "${tools.build_ip container}"
      }
      rule {
        target_label  = "service"
        replacement   = "alloy"
      }
      forward_to = [prometheus.remote_write.metrics_service.receiver]
    }

    prometheus.remote_write "metrics_service" {
      endpoint {
        url = "http://${tools.metrics_addr}/api/v1/write"
      }
    }
  '';
}
