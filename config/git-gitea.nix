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
      # TODO: dump ...
      settings = {
        server.HTTP_PORT = 3000;
      };
      # user = "git";
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
