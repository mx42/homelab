{
  pkgs,
  lib,
  modulesPath,
  ...
}:
let
  infra = import ./constants.nix;
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
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  time.timeZone = infra.default_tz;

  users.users.root = {
    openssh.authorizedKeys.keys = [
      infra.master_public_ssh_key
    ];
    initialPassword = "nixos";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  system.stateVersion = "25.11";
}
