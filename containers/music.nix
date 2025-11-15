{ nixpkgs, system, ... }:
let
  pkgs = nixpkgs.legacyPackages.${system};
in
{
  my-lxc.music = {
    container = {
      cores = 2;
      memory = 2048;
      disk = "6G";
      swap = 512;
    };
    system = {
      port = 8095;
      additionalPorts = [
        8097
      ];
      services.music-assistant = {
        enable = true;
        providers = [
          "builtin"
          "builtin_player"
          "chromecast"
          "deezer"
          "dlna"
          "filesystem_local"
          "filesystem_smb"
          "hass"
          "hass_players"
          "jellyfin"
          "player_group"
          "ytmusic"
        ];
      };
      packages = with pkgs; [
        cifs-utils
        util-linux
      ];
    };
    logging = {
      enable = true;
      metricsEnable = true;
    };
    private = true;
    auth = false;
  };
}
