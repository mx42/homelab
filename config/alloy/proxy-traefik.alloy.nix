{ config, tools, ... }:
let
  hostname = tools.build_hostname "proxy";
  ip = tools.build_ip "proxy";
in
{
  out = ''
    loki.relabel "trf_journal" {
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

    loki.source.journal "trf_journal_scrape" {
      forward_to = [loki.process.trf_router.receiver]
      matches = "_SYSTEMD_UNIT=traefik.service"
      relabel_rules = loki.relabel.trf_journal.rules
      labels = {
        service = "traefik",
        host = "${hostname}",
        host_ip = "${ip}",
      }
    }
    loki.process "trf_router" {
      stage.regex {
        expression = "^(?P<datetime>\\S+) (?P<level>\\w{3}) (?P<message>.*)$"
      }
      stage.timestamp {
        source = "datetime"
        format = "2006-01-02 15:04:05-07:00"
      }
      stage.replace {
        source = "level"
        expression = "INF"
        replace = "INFO"
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
