{
  config,
  system,
  nixpkgs,
  ...
}:
let
  pkgs = nixpkgs.legacyPackages.${system};
  lib = pkgs.lib;
  inherit (lib) types mkOption mkEnableOption;
  cfg = config.my-lxc or { };
  realcfg = config;
  nixosTemplate = import ./lxc-template.nix { inherit pkgs; };
  tools = import ./tools.nix { inherit config lib; };
  mergeConf = c: (lib.foldl' (acc: e: lib.recursiveUpdate acc e) { } c);

  secrets = import ../secrets/secrets.nix;
in
{
  options = with types; {
    # Inputs
    my-lxc = mkOption {
      type = attrsOf (submodule {
        options = {
          container = mkOption {
            type = submodule {
              options = {
                enable = mkOption {
                  type = bool;
                  description = "Enable the container terraform generation";
                  default = true;
                };
                cores = mkOption {
                  type = int;
                  description = "Number of CPU";
                  default = 1;
                };
                memory = mkOption {
                  type = int;
                  description = "Ram in MB";
                  default = 512;
                };
                unprivileged = mkOption {
                  type = bool;
                  default = true;
                  description = "Make an unprivileged container";
                };
                disk = mkOption {
                  type = str;
                  description = "Disk size";
                  default = "4G";
                };
                swap = mkOption {
                  type = nullOr int;
                  description = "Optional swap size in MB";
                  default = null;
                };
                tags = mkOption {
                  type = listOf str;
                  description = "Container tags (terraform is automatically added)";
                  default = [ ];
                };
                overrides = mkOption {
                  type = attrs;
                  description = "Overrides to the Proxmox LXC Terraform resource";
                  default = { };
                };
                protection = mkOption {
                  type = bool;
                  description = "Whether container should be protected against changes.";
                  default = true;
                };
                # TODO: Device passthrough & mount points => use overrides for now - or do it manually...
                #    => in /etc/pve/lxc/{id}.conf
                #    mp{number}: /pve/path,mp=/container/path  # <- for bind-mount
                #    dev{number}: /dev/{...}                   # <- for device pass-through
              };
            };
          };
          system = mkOption {
            type = submodule {
              options = {
                port = mkOption {
                  type = nullOr int;
                  description = "Main exposed HTTP port";
                  default = null;
                };
                additionalPorts = mkOption {
                  type = listOf int;
                  description = "TCP ports to open";
                  default = [ ];
                };
                udpPorts = mkOption {
                  type = listOf int;
                  description = "UDP ports to open";
                  default = [ ];
                };
                services = mkOption {
                  type = attrs;
                  description = "NixOS services to enable";
                  default = { };
                };
                packages = mkOption {
                  type = listOf package;
                  description = "NixOS packages to add";
                  default = [ ];
                };
                etcFiles = mkOption {
                  type = attrs;
                  description = "Files to create on NixOS (=> environment.etc)";
                  default = { };
                };
                additional = mkOption {
                  type = attrs;
                  description = "Additional NixOS definitions to be merged to nixosModule";
                  default = { };
                };
                importConfig = mkOption {
                  type = listOf path;
                  description = "Modules to import and merge to NixOS module";
                  default = [ ];
                };
              };
            };
          };
          db = mkOption {
            type = submodule {
              options = {
                enable = mkEnableOption "Create a DB";
                password = mkOption { type = str; };
                additionalDB = mkOption {
                  type = listOf str;
                  default = [ ];
                };
              };
            };
            default = { };
          };
          logging = mkOption {
            type = submodule {
              options = {
                enable = mkEnableOption "Whether to enable default logs collection";
                metricsEnable = mkEnableOption "Whether to enable default metrics collection";
                prometheusPorts = mkOption {
                  type = listOf int;
                  description = "Ports of Prometheus Exporters";
                  default = [ ];
                };
                alloyConfig = mkOption {
                  type = attrsOf path;
                  description = "Name => paths to add to Alloy";
                  default = { };
                };
                journalLoggers = mkOption {
                  type = attrsOf (nullOr str);
                  description = "Service => routing stages (if any) as str";
                  default = { };
                };
              };
            };
          };
          private = mkOption {
            type = bool;
            description = "Should be only exposed to the private network";
            default = true;
          };
          auth = mkOption {
            type = bool;
            description = "Should be accessed through the auth middleware";
            default = true;
          };
          otherDomains = mkOption {
            type = listOf (submodule {
              options = {
                subdomain = mkOption { type = str; };
                port = mkOption { type = int; };
                private = mkOption {
                  type = bool;
                  default = true;
                };
                auth = mkOption {
                  type = bool;
                  default = true;
                };
                customRule = mkOption {
                  type = nullOr str;
                  default = null;
                };
                raw_tcp = mkOption {
                  type = bool;
                  default = false;
                };
              };
            });
            default = [ ];
          };
          sso = mkOption {
            type = attrs;
            description = "SSO parameters (TBD)";
            default = { };
          };
          secrets = mkOption {
            type = attrs;
            description = "Secrets to import {name}: {path}";
            default = { };
          };
        };
      });
    };

    # in _id.nix
    id = mkOption {
      type = attrsOf int;
    };
    # in _config.nix
    globals = mkOption {
      type = submodule {
        options = {
          ip_prefix = mkOption { type = str; };
          cidr = mkOption { type = int; };
          gateway = mkOption { type = str; };
          domains = mkOption {
            type = submodule {
              options = {
                internal = mkOption { type = str; };
                external = mkOption { type = str; };
              };
            };
          };
          master = mkOption {
            type = submodule {
              options = {
                login = mkOption { type = str; };
                email = mkOption { type = str; };
                public_ssh_key = mkOption { type = str; };
                initial_htpasswd = mkOption { type = str; };
              };
            };
          };
          default_tz = mkOption { type = str; };
          country_code = mkOption { type = str; };
          currency = mkOption { type = str; };
          services = mkOption {
            type = submodule {
              log_sink = mkOption { type = str; }; # ip:port
              metrics_sink = mkOption { type = str; }; # ip:port
            };
          };

          dns_provider = mkOption { type = str; };

          other_hosts = mkOption {
            type = listOf (submodule {
              options = {
                hostname = mkOption { type = str; };
                private = mkOption {
                  type = bool;
                  default = true;
                };
                auth = mkOption {
                  type = bool;
                  default = true;
                };
                addr = mkOption {
                  type = str;
                  description = "ip:port for the service";
                };
                useCustomCA = mkOption {
                  type = bool;
                  default = false;
                  description = "Whether to use a custom CA (pretty much hardcoded)";
                };
              };
            });
            default = [ ];
          };
        };
      };
    };

    # Outputs
    tf = mkOption {
      type = types.attrs;
      description = "Terraform resources";
      default = { };
    };
    nixosModule = mkOption {
      type = types.attrs;
      description = "NixOS system";
      default = { };
    };
  };

  config = {

    tf.resource = mergeConf [
      (import ./containers-terraform-postgres.nix { inherit config tools lib; })
      (import ./containers-terraform-proxmox.nix { inherit config tools lib; })
      (import ./containers-terraform-authentik.nix { inherit config tools lib; })
    ];

    nixosModule = lib.mapAttrs (
      container: def:
      { config, pkgs, ... }:
      let
        keys = import ../config/_keys.nix;
        ownKey = if (lib.hasAttr container keys) then keys.${container} else null;
      in
      mergeConf [
        (mergeConf (
          lib.attrValues (
            lib.mapAttrs (
              secretName': _:
              let
                secretName = lib.removeSuffix ".age" secretName';
              in
              {
                age.secrets.${secretName}.file = ../secrets/${secretName'};
              }
            ) (lib.filterAttrs (_: entry: builtins.elem ownKey entry.publicKeys) secrets)
          )
        ))
        nixosTemplate
        (lib.optionalAttrs (def.logging.enable) import ./containers-nixos-logging.nix {
          inherit
            config
            tools
            container
            def
            pkgs
            ;
        })
        {
          networking.hostName = container;
          networking.firewall = {
            enable = true;
            allowedTCPPorts =
              def.system.additionalPorts
              ++ (if (def.system.port != null) then [ def.system.port ] else [ ])
              ++ (if (def.logging.enable) then [ 12345 ] else [ ]);
            allowedUDPPorts = def.system.udpPorts;
          };
          services = def.system.services;
          environment.etc = def.system.etcFiles;
          environment.systemPackages = def.system.packages;
        }
        def.system.additional
        (mergeConf (
          map (
            p:
            import p {
              inherit pkgs tools;
              config = mergeConf [
                realcfg
                config
              ];
            }
          ) def.system.importConfig
        ))
      ]

    ) cfg;
  };
}
