{
  pkgs,
  config,
  tools,
  ...
}:
{
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    package = pkgs.postgresql_18;
    authentication = ''
      host all all ${tools.mask_cidr} md5
    '';
    checkConfig = true;
    initialScript = config.age.secrets.db-postgres-initscript.path;
  };

  # TODO: Manually add /mnt/backups mountpoint => NAS backup folder (with rotation on the NAS)
  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    compression = "gzip";
    compressionLevel = 6;
    location = "/mnt/backups/postgresql";
  };
}
