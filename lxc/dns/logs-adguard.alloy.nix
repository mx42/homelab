{ ip, domainname, ... }:
{
  out = ''
    loki.relabel "agh_journal" {
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
    loki.source.journal "agh_journal_scrape" {
      forward_to = [loki.process.agh_router.receiver]
      matches = "_SYSTEMD_UNIT=adguardhome.service"
      relabel_rules = loki.relabel.agh_journal.rules
      labels = {
        service = "adguardhome",
        host = "${domainname}",
        host_ip = "${ip}",
      }
    }

    loki.process "agh_router" {
      stage.regex {
        expression = "^(?P<timestamp>\\S+ \\S+) \\[(?P<level>\\w+)\\] (?P<message>.*)$"
      }

      stage.timestamp {
        source = "timestamp"
        format = "2006-01-02 15:04:05"
      }

      stage.labels {
        values = {
          level = "level",
        }
      }

      stage.output {
        source = "message"
      }

      forward_to = [loki.write.grafana_loki.receiver]
    }
  '';
}
