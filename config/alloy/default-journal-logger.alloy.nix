{
  tools,
  container,
  service,
  additional_stages,
  ...
}:
let
  hostname = tools.build_hostname container;
  ip = tools.build_ip container;
  prefix = "${container}_${service}";
in
{
  out = ''
        loki.relabel "${prefix}_journal" {
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
        loki.source.journal "${prefix}_journal_scrape" {
          forward_to = [loki.process.${prefix}_router.receiver]
          matches = "_SYSTEMD_UNIT=${service}.service"
          relabel_rules = loki.relabel.${prefix}_journal.rules
          labels = {
            service = "${service}",
            host = "${hostname}",
            host_ip = "${ip}",
          }
        }

    loki.process "${prefix}_router" {

      ${additional_stages}

      forward_to = [loki.write.grafana_loki.receiver]
    }
  '';
}
