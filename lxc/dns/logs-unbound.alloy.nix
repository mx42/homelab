{ ip, domainname, ... }:
{
  out = ''
        loki.relabel "unbd_journal" {
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
        loki.source.journal "unbd_journal_scrape" {
          forward_to = [loki.process.unbd_router.receiver]
          matches = "_SYSTEMD_UNIT=unbound.service"
          relabel_rules = loki.relabel.unbd_journal.rules
          labels = {
            service = "unbound",
            host = "${domainname}",
            host_ip = "${ip}",
          }
        }

    loki.process "unbound_router" {
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

      forward_to = [loki.write.grafana_loki.receiver]
    }
  '';
}
