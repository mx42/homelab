{
  pkgs,
  ...
}:
let
  lib = pkgs.lib;
  modulesPath = pkgs.path + "/nixos/modules";
  config = import ../config/_globals.nix { };
  id = (import ../config/_ids.nix { }).id;
in
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  boot.isContainer = true;

  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];
  services.journald.extraConfig = ''
    SystemMaxUse=200M
    SystemKeepFree=100M
    SystemMaxFileSize=20M
    SystemMaxFiles=10
    MaxRetentionSec=5day
  '';
  environment.systemPackages = with pkgs; [
    vim
    openssl
    coreutils
  ];
  services.openssh.enable = true;
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 3d";
  };
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };
  networking.nameservers =
    (
      if (lib.hasAttr "dns" id) then [ "${config.globals.ip_prefix}${toString (id.dns - 1000)}" ] else [ ]
    )
    ++ [ "9.9.9.9" ];

  time.timeZone = config.globals.default_tz;

  users.users.root = {
    openssh.authorizedKeys.keys = [
      config.globals.master.public_ssh_key
    ];
    initialPassword = "nixos";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  system.stateVersion = "25.11";
}
