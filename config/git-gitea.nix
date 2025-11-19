{
  pkgs,
  config,
  tools,
  ...
}:
{
  services = {
    gitea = {
      enable = true;
      database = {
        type = "postgres";
        user = "git";
        name = "git";
        password = config.my-lxc.git.db.password;
        host = tools.build_ip "db";
        createDatabase = false;
      };
      settings = {
        server.HTTP_PORT = 3000;
      };
      dump = {
        enable = true;
        # TODO: Manual mountpoint /mnt/backups => NAS
        backupDir = "/mnt/backups/gitea";
        interval = "1:42";
        type = "tar.gz";
      };
    };
    # gitea-actions-runner.instances.default = {
    #   enable = true;
    #   labels = [
    #     "test"
    #     "nixos"
    #   ];
    # };
  };
}
