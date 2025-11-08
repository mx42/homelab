{
  config,
  tools,
  pkgs,
  ...
}:
let
  yaml = pkgs.format.yaml { };
in
{
  environment.systemPackages = [
    pkgs.matrix-authentication-service
  ];
  environment.etc = {
    "mas/config.yaml".source = yaml.generate "mas-config.yaml" (
      import ./matrix-mas.config.yaml { inherit config tools; }
    );
    "alloy/logs-mas.alloy".text = (import ./alloy/matrix-mas.alloy.nix { inherit config tools; }).out;
  };
  systemd.services.matrix-authentication-service = {
    enable = true;
    description = "Matrix Authentication Service";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.matrix-authentication-service}/bin/mas-cli server --config /etc/mas/config.yaml";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
