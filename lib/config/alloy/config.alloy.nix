let
  infra = import ../../constants.nix;
in
{
  out = ''
    logging {
      level = "warning"
    }
    loki.write "grafana_loki" {
      endpoint {
        url = "http://${infra.loki_addr}/loki/api/v1/push"
      }
    }
  '';
}
