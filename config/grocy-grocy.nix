{
  config,
  tools,
  pkgs,
  ...
}:
let
  lib = pkgs.lib;
in
{
  services.grocy = {
    enable = true;
    hostName = tools.build_hostname "grocy";
    settings = {
      calendar.firstDayOfWeek = 1;
      culture = config.globals.country_code;
      currency = config.globals.currency;
    };
    nginx.enableSSL = false;
  };
  environment.etc."grocy/config.php".text = lib.mkAfter ''
    // Arbitrary PHP code in grocy's configuration file
    Setting('AUTH_CLASS', 'Grocy\Middleware\ReverseProxyAuthMiddleware');
    Setting('REVERSE_PROXY_AUTH_HEADER', 'REMOTE_USER');
  '';
}
