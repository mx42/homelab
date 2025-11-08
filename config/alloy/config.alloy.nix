{
  tools,
  ...
}:
{
  out = ''
    logging {
      level = "warn"
    }
    loki.write "grafana_loki" {
      endpoint {
        url = "http://${tools.loki_addr}/loki/api/v1/push"
      }
    }
  '';
}
