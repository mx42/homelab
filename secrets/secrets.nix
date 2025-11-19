let
  config = (import ../config/_globals.nix { }).globals;
  users = [
    config.master.public_ssh_key
  ];

  keys = import ../config/_keys.nix;
  common = builtins.attrValues (keys);
in
{
  # TODO: Probably there would be a way to guess the default service key from the secret prefix
  "auth-authentik-ldap-secrets.age".publicKeys = users ++ [
    keys.auth
  ];
  "auth-authentik-proxy-secrets.age".publicKeys = users ++ [
    keys.auth
  ];
  "auth-authentik-secrets.age".publicKeys = users ++ [
    keys.auth
  ];
  "db-postgres-initscript.age".publicKeys = users ++ [
    keys.db
  ];
  "finances-app-key.age".publicKeys = users ++ [
    keys.finances
  ];
  "matrix-maubot-cfg.age".publicKeys = users ++ [
    keys.matrix
  ];
  "metrics-pve.age".publicKeys = users ++ [
    keys.metrics
  ];
  "power-password-file.age".publicKeys = users ++ [
    keys.power
  ];
  "proxy-dns-provider-config.age".publicKeys = users ++ [
    keys.proxy
  ];
  "yarrr-env.age".publicKeys = users ++ [
    keys.yarrr
  ];
}
