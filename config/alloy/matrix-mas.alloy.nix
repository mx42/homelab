{ ip, domainname, ... }:
{
  out = ''
        loki.relabel "mas_journal" {
          forward_to = []
          rule {
            source_labels = ["__journal__priority_keyword"]
            target_label = "level"
          }
          rule {
            source_labels = ["__journal__SYSLOG_IDENTIFIER"]
            target_label = "app"
          }
        }
        loki.source.journal "mas_journal_scrape" {
          forward_to = [loki.process.mas_router.receiver]
          matches = "_SYSTEMD_UNIT=matrix-authentication-service.service"
          relabel_rules = loki.relabel.mas_journal.rules
          labels = {
            service = "matrix-authentication-service",
            host = "${domainname}",
            host_ip = "${ip}",
          }
        }

    loki.process "mas_router" {
      stage.regex {
        expression = "^(?P<timestamp>\\S+)  (?P<level>\\S+) (?P<facility>\\S+) (?P<worker>\\S+) - (?P<message>.*)$"
      }

      stage.timestamp {
        source = "timestamp"
        format = "RFC3339Nano"
      }

      stage.labels {
        values = {
          level = "",
          facility = "",
          worker = "",
        }
      }
      
      stage.output {
        source = "message"
      }

      forward_to = [loki.write.grafana_loki.receiver]
    }
  '';
}
