{
  config,
  tools,
  container,
  def,
  pkgs,
  ...
}:
let
  lib = pkgs.lib;
  mergeConf = c: (lib.foldl' (acc: e: lib.recursiveUpdate acc e) { } c);
in
{
  services.alloy = {
    enable = true;
    extraFlags = [
      "--server.http.listen-addr=0.0.0.0:12345"
      "--disable-reporting"
    ];
  };
  environment.etc = mergeConf (
    [
      {
        "alloy/config.alloy".text = (import ../config/alloy/config.alloy.nix { inherit config tools; }).out;
        "alloy/metrics.alloy".text =
          if (def.logging.metricsEnable) then
            (import ../config/alloy/metrics.alloy.nix { inherit config tools container; }).out
          else
            "";
      }
    ]
    ++ (lib.mapAttrsToList (filename: file: {
      "alloy/${filename}.alloy".text = (import file { inherit config tools container; }).out;
    }) def.logging.alloyConfig)
    ++ (lib.mapAttrsToList (service: additional_stages: {
      "alloy/${container}-${service}.alloy".text =
        import ../config/alloy/default-journal-logger.alloy.nix
          {
            inherit
              tools
              container
              service
              additional_stages
              ;
          };
    }) def.logging.journalLoggers)
  );

}
