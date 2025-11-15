{
  config,
  pkgs,
  tools,
  ...
}:
{
  environment.etc."yarrr.env".source = config.age.secrets.yarrr-env.path;

  services = {
    bazarr = {
      enable = true;
      openFirewall = true; # 6767
      user = "root";
      group = "root";
    };
    lidarr = {
      enable = true;
      openFirewall = true; # 8686
      user = "root";
      group = "root";
      environmentFiles = [ "/etc/yarrr.env" ];
      dataDir = "/mnt/nas/app-data/lidarr"; # TODO: Manual bind-mount in Proxmox
    };
    radarr = {
      enable = true;
      openFirewall = true; # 7878
      user = "root";
      group = "root";
      environmentFiles = [ "/etc/yarrr.env" ];
    };
    sonarr = {
      enable = true;
      openFirewall = true; # 8989
      user = "root";
      group = "root";
      environmentFiles = [ "/etc/yarrr.env" ];
    };
    readarr = {
      enable = true;
      openFirewall = true; # 8787
      user = "root";
      group = "root";
      environmentFiles = [ "/etc/yarrr.env" ];
    };
    prowlarr = {
      enable = true;
      openFirewall = true; # 9696
    };
    recyclarr = {
      enable = true;
    };
    prometheus.exporters = {
      exportarr-bazarr.enable = true;
      exportarr-bazarr.openFirewall = true;
      exportarr-lidarr.enable = true;
      exportarr-lidarr.openFirewall = true;
      exportarr-prowlarr.enable = true;
      exportarr-prowlarr.openFirewall = true;
      exportarr-radarr.enable = true;
      exportarr-radarr.openFirewall = true;
      exportarr-readarr.enable = true;
      exportarr-readarr.openFirewall = true;
      exportarr-sonarr.enable = true;
      exportarr-sonarr.openFirewall = true;
    };
  };
}
