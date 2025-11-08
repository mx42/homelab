{
  config,
  tools,
  pkgs,
  ...
}:
let
  container = "monitoring";
  hostname = tools.build_hostname container;
in
{
  services.grafana = {
    enable = true;
    openFirewall = true;
    declarativePlugins = [
      pkgs.grafanaPlugins.grafana-mqtt-datasource
      pkgs.grafanaPlugins.grafana-lokiexplore-app
      pkgs.grafanaPlugins.grafana-metricsdrilldown-app
    ];
    provision = {
      enable = true;
      alerting = { };
      dashboards = { };
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://${tools.metrics_addr}";
          jsonData = {
            prometheusType = "Prometheus";
            timeInterval = "30s";
          };
        }
        {
          name = "Loki";
          type = "loki";
          url = "http://localhost:3100/";
        }
      ];
    };

    settings = {
      analytics = {
        feedback_links_enabled = false;
        reporting_enabled = false;
        check_for_plugin_updates = false;
        check_for_updates = false;
      };
      database = {
        host = tools.build_ip "db";
        name = container;
        password = config.my-lxc.monitoring.db.password;
        # ssl_mode = "require" ?
        type = "postgres";
        user = container;
      };
      security = {
        # CSP?
        admin_email = config.globals.master.email;
        admin_user = config.globals.master.login;
        cookie_secure = true;
        data_source_proxy_whitelist = [
          (tools.build_ip "auth")
        ];
      };
      server = {
        enable_gzip = true;
        root_url = "https://${hostname}/";
        http_addr = tools.build_ip container;
        http_port = 3000;
        protocol = "http";
      };
    };
  };
}
