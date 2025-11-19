{
  pkgs,
  config,
  tools,
  ...
}:
{
  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  environment.etc."maubot/config.base.yaml".source = config.age.secrets.matrix-maubot-cfg.path;
  services.maubot = {
    enable = true;
    plugins = with config.services.maubot.package.plugins; [
      rss
      hasswebhookbot
    ];
    configMutable = true;
    # RIP the auto configuration ... Built a base yaml, written in agenix, and manually copying this to the config.yaml file + adapting as needed...
    extraConfigFile = "/etc/maubot/config.yaml";
  };
}
