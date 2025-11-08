{
  config,
  tools,
  pkgs,
  ...
}:
let
  json = pkgs.formats.json { };
in
{
  environment = {
    systemPackages = [
      pkgs.element-web
      pkgs.synapse-admin-etkecc
    ];
    etc."alloy/logs-nginx.alloy".text =
      (import ./alloy/default-journal-logger.alloy.nix {
        inherit tools;
        container = "matrix";
        service = "nginx";
      }).out;
  };
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    virtualHosts.element-web = {
      root = pkgs.element-web;
      locations = {
        "/" = {
          tryFiles = "$uri $uri/ /index.html?$query_string";
          index = "index.html";
        };
        "= /config.json" = {
          alias = json.generate "element.config.json" (
            import ./config/matrix-element.config.nix { inherit tools config; }
          );
        };
      };
    };
    virtualHosts.synapse-admin = {
      root = pkgs.synapse-admin-etkecc;
      listen = [
        {
          addr = "0.0.0.0";
          port = 5173;
        }
      ];
      locations = {
        "/" = {
          tryFiles = "$uri $uri/ /index.html?$query_string";
          index = "index.html";
        };
        "= /config.json" = {
          alias = json.generate "synapse-admin.config.json" (
            import ./config/matrix-synapse-admin.config.nix { inherit tools config; }
          );
        };
      };
    };
  };
}
