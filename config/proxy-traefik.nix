{
  tools,
  config,
  pkgs,
  ...
}:
let
  lib = pkgs.lib;
  ip = h: tools.build_ip h;
  dmn = config.globals.domains.external;
  internal = "&& ClientIP(`${tools.mask_cidr}`)";
  mergeConf = c: (lib.foldl' (acc: e: lib.recursiveUpdate acc e) { } c);
  # NOTE: For now this is built manually on the host.
  customCAs = [
    "/var/lib/traefik/ca.public.crt"
  ];
in
{
  services = {
    traefik = {
      enable = true;
      environmentFiles = [
        config.age.secrets.proxy-dns-provider-config.path
      ];
      staticConfigOptions = {
        api.insecure = true;
        log.level = "INFO";
        accessLog = {
          filters.statusCodes = [
            "200"
            "400-404"
            "500-503"
          ];
          fields = {
            names.ClientUsername = "drop";
            headers.defaultMode = "drop";
          };
        };
        entryPoints = {
          web.address = ":80";
          websecure.address = ":443";
          traefik.address = ":8080";
          metrics.address = ":8082";
          dbsecure.address = ":5432";
        };
        certificatesResolvers = {
          letsencrypt = {
            acme = {
              email = config.globals.master.email;
              storage = "/var/lib/traefik/acme";
              httpChallenge = {
                entryPoint = "web";
              };
              dnsChallenge = {
                provider = config.globals.dns_provider;
              };
            };
          };
        };
        tls = {
          options = {
            modern = {
              minVersion = "VersionTLS13";
            };
            intermediate = {
              minVersion = "VersionTLS12";
              cipherSuites = [
                "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
                "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
                "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
                "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
                "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305"
                "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
              ];
            };
          };
        };
        metrics = {
          prometheus = {
            entryPoint = "metrics";
            addEntryPointsLabels = true;
            addRoutersLabels = true;
            addServicesLabels = true;
          };
        };
        experimental.plugins = {
          staticResponse = {
            moduleName = "github.com/jdel/staticresponse";
            version = "v0.0.1";
          };
        };
      };
      dynamicConfigOptions = {
        tcp = {
          # TODO: Build both routers+services in 1 pass.
          routers = mergeConf (
            lib.concatLists (
              lib.mapAttrsToList (
                ct: def:
                (map (
                  d:
                  lib.optionalAttrs (d.raw_tcp == true) {
                    ${d.subdomain} = {
                      rule = (
                        if (d.customRule != null) then
                          (lib.replaceStrings [ "#DOMAIN#" ] [ dmn ] d.customRule)
                        else
                          ("HostSNI(`${d.subdomain}${dmn}`) " + (if (d.private == true) then internal else ""))
                      );
                      service = "${d.subdomain}-service";
                      entryPoints = [ "dbsecure" ]; # not really flexible
                      middlewares = [ ];
                      tls.certResolver = "letsencrypt";
                    };
                  }
                ) def.otherDomains)
              ) config.my-lxc
            )
          );
          services = mergeConf (
            lib.concatLists (
              lib.mapAttrsToList (
                ct: def:
                (map (
                  d:
                  lib.optionalAttrs (d.raw_tcp == true) {
                    "${d.subdomain}-service" = {
                      loadBalancer.servers = [
                        { address = "${ip ct}:${toString d.port}"; }
                      ];
                    };
                  }
                ) def.otherDomains)
              ) config.my-lxc
            )
          );
        };
        http = {
          middlewares = {
            authentik.forwardAuth = {
              address = "http://${ip "auth"}:9000/outpost.goauthentik.io/auth/traefik";
              trustForwardHeader = true;
              authResponseHeaders = [
                "X-authentik-username"
                "X-authentik-groups"
                "X-authentik-entitlements"
                "X-authentik-email"
                "X-authentik-name"
                "X-authentik-uid"
                "X-authentik-jwt"
                "X-authentik-meta-jwks"
                "X-authentik-meta-outpost"
                "X-authentik-meta-provider"
                "X-authentik-meta-app"
                "X-authentik-meta-version"
                "Remote-User"
                "Remote-Group"
                "Remote-Email"
                "Remote-Name"
              ];
            };
            matrix-wellknown.plugin.staticResponse = {
              statusCode = 200;
              body = ''{"m.server": "${tools.build_hostname "matrix"}:443"}'';
              headers = {
                "Content-Type" = "application/json";
              };
            };
          };
          routers =
            mergeConf (
              lib.concatLists (
                (lib.mapAttrsToList (
                  ct: def:
                  (map (
                    d:
                    lib.optionalAttrs (d.raw_tcp == false) {
                      ${d.subdomain} = {
                        rule = (
                          if (d.customRule != null) then
                            (lib.replaceStrings [ "#DOMAIN#" ] [ dmn ] d.customRule)
                          else
                            ("Host(`${d.subdomain}${dmn}`) " + (if (d.private == true) then internal else ""))
                        );
                        service = "${d.subdomain}-service";
                        entryPoints = [ "websecure" ];
                        middlewares = if (d.auth) then [ "authentik" ] else [ ];
                        tls.certResolver = "letsencrypt";
                      };
                    }
                  ) def.otherDomains)
                  ++ [
                    (lib.optionalAttrs (def.system.port != null) {
                      ${ct} = {
                        rule = "Host(`${ct}${dmn}`) " + (if (def.private == true) then internal else "");
                        service = "${ct}-service";
                        entryPoints = [ "websecure" ];
                        middlewares = if (def.auth) then [ "authentik" ] else [ ];
                        tls.certResolver = "letsencrypt";
                      };
                    })
                  ]
                ) config.my-lxc)
                ++ [
                  (map (h: {
                    ${h.hostname} = {
                      rule = "Host(`${h.hostname}${dmn}`) " + (if (h.private == true) then internal else "");
                      service = "${h.hostname}-service";
                      entryPoints = [ "websecure" ];
                      middlewares = if (h.auth) then [ "authentik" ] else [ ];
                      tls.certResolver = "letsencrypt";
                    };
                  }) config.globals.other_hosts)
                ]
              )
            )
            // {
              matrix-wellknown = {
                rule = "Path(`/\.well-known/matrix/server`)";
                entryPoints = [ "websecure" ];
                service = "noop";
                middlewares = [ "matrix-wellknown" ];
                tls.certResolver = "letsencrypt";
              };
            }

          ;
          services =
            mergeConf (
              lib.concatLists (
                (lib.mapAttrsToList (
                  ct: def:
                  (map (d: {
                    "${d.subdomain}-service" = {
                      loadBalancer.servers = [
                        { url = "http://${ip ct}:${toString d.port}/"; }
                      ];
                    };
                  }) def.otherDomains)
                  ++ [
                    (
                      (lib.optionalAttrs (def.system.port != null) {
                        "${ct}-service" = {
                          loadBalancer.servers = [ { url = "http://${ip ct}:${toString def.system.port}/"; } ];
                        };
                      })
                    )
                  ]
                ) config.my-lxc)
                ++ [
                  (map (h: {
                    "${h.hostname}-service" = {
                      loadBalancer = {
                        servers = [ { url = h.addr; } ];
                      }
                      // (lib.optionalAttrs (h.useCustomCA) {
                        serversTransport = "${h.hostname}-transport";
                      });
                    };
                  }) config.globals.other_hosts)
                ]
              )
            )
            // {
              noop.loadBalancer.servers = [ ];
            };
          serversTransports = mergeConf (
            (map (
              h:
              lib.optionalAttrs (h.useCustomCA) {
                "${h.hostname}-transport" = {
                  rootCAs = customCAs;
                };
              }
            ) config.globals.other_hosts)
          );
        };
      };
    };
  };
}
